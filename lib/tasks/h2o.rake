namespace :h2o do

  task(:benchmark_test => :environment) do
    require 'benchmark'
    Benchmark.bm do |x|
      x.report do
        5.times do
          Playlist.tag_list
        end
      end
    end
    Benchmark.bm do |x|
      x.report do
        5.times do
          b = Playlist.all.collect { |p| p.tag_list }.flatten
          c = b.inject({}) { |h, a| h[a] ||= 0; h[a]+=1; h }
          c.sort_by { |k, v| v }.reverse[0..25]
        end
      end
    end
  end

  desc 'Update item karma'
  task(:update_user_karma => :environment) do
    Rails.cache.delete_matched(%r{user-barcode-*})
    User.find_in_batches(:batch_size => 20) do |items|
      items.each do |i|
        i.update_karma
      end
    end
  end

  desc 'Deep Playlist Copy'
  task(:deep_playlist_copy => :environment) do
    #p = Playlist.find(1304)
    #u = User.find(534)
    #if(p.nil? || u.nil?)
    #  puts "You must enter a valid playlist and user id to clone."
    #end
    #pp = PlaylistPusher.new(:playlist_id => [p.id], :user_ids => [u.id])
    #pp.push!
  end

  desc 'Clear Static Page Caches'
  task(:clear_static_page_cache => :environment) do
    system("rm -rf #{RAILS_ROOT}/public/p/*")
  end
  
  desc 'Clear Page Caches'
  task(:clear_page_cache => :environment) do
    system("rm -rf #{RAILS_ROOT}/public/collages/*")
    system("rm -rf #{RAILS_ROOT}/public/playlists/*")
    system("rm -rf #{RAILS_ROOT}/public/cases/*")
  end
  
  desc 'Clear UI Caches'
  task(:clear_ui_cache => :environment) do
    system("rm -rf #{RAILS_ROOT}/public/stylesheets/all.css")
    system("rm -rf #{RAILS_ROOT}/public/javascripts/all.js")
  end

  desc 'Clear Homepage Cache'
  task(:clear_homepage_cache => :environment) do
    system("rm -rf #{RAILS_ROOT}/public/index.html")
  end
  
  desc 'Clear All Cache'
  task(:clear_all_cache => :environment) do
    system("rm -rf #{RAILS_ROOT}/tmp/cache/*")
    Rake::Task["h2o:clear_ui_cache"].execute
    Rake::Task["h2o:clear_page_cache"].execute
    Rake::Task["h2o:clear_homepage_cache"].execute
  end

  desc 'Test case import'
  task(:import_cases => :environment) do
    # -i --add-xml-decl n --doctype omit --show-body-only true
    TidyFFI::Tidy.default_options.add_xml_decl = false
    TidyFFI::Tidy.default_options.doctype = 'omit'
    TidyFFI::Tidy.default_options.show_body_only = 1
    TidyFFI::Tidy.default_options.output_xhtml = true

    metadata_hash = {}
    FasterCSV.foreach("#{RAILS_ROOT}/tmp/cases/cases.csv", {:headers => :first_row, :header_converters => :symbol}) do |row|
      row_hash = row.to_hash
      metadata_hash[row_hash[:filename]] = row_hash
    end

    Dir.glob("#{RAILS_ROOT}/tmp/cases/*.xml").each do |file|
      c = Case.new()
      basename = Pathname(file).basename.to_s
#      puts file
      doc = Nokogiri::XML.parse(File.open(file))
      unless metadata_hash[basename].blank?
        c.tag_list = metadata_hash[basename][:tags]
      end

#      c.tag_list = 'testimport'
      c.current_opinion = (doc.xpath('//Case/CurrentOpinion').text == 'False') ? false : true

      c.short_name = doc.xpath('//Case/ShortName').text
      c.full_name = doc.xpath('//Case/ShortName').text

      #Done like this because Time.parse doesn't deal with dates before 1901
      date = doc.xpath('//Case/DecisionDate').text
      unless date.blank?
        date_array = date.split(/\D/)
        c.decision_date = "#{date_array[2]}-#{date_array[0]}-#{date_array[1]}"
      end
      c.author = doc.xpath('//Case/Author').text

      cj = CaseJurisdiction.find_or_create_by_abbreviation_and_name(
        doc.xpath('//Case/Jurisdiction/CourtAbbreviation').text, 
        doc.xpath('//Case/Jurisdiction/CourtName').text
      )

      c.case_jurisdiction = cj

      doc.xpath('//Case/Citations/Citation').each do |cite|
        c.case_citations << CaseCitation.find_or_create_by_volume_and_reporter_and_page(
          cite.xpath('Volume').text || '', 
          cite.xpath('Reporter').text || '',
          cite.xpath('Page').text || ''
        )
      end

      doc.xpath('//Case/DocketNumbers/DocketNumber').each do |docket|
        unless docket.text.blank?
          c.case_docket_numbers << CaseDocketNumber.find_or_create_by_docket_number(docket.text)
        end
      end

      c.party_header = doc.xpath('//Case/PartyHeader').text
      c.lawyer_header = doc.xpath('//Case/LawyerHeader').text
      c.header_html = doc.xpath('//Case/HeaderHtml').text

#      puts
#      puts "Content of #{file}, pre-stripping: "
#      puts  "#{doc.xpath('//Case/HeaderHtml').text} #{doc.xpath('//Case/CaseHtml').text}"

      tidy_content = TidyFFI::Tidy.new("#{doc.xpath('//Case/HeaderHtml').text} #{doc.xpath('//Case/CaseHtml').text}")

      c.content = tidy_content.clean
      if c.content.blank?
        puts
        puts "Case: #{file} had content problems, using HTML raw"
        puts
        c.content = "#{doc.xpath('//Case/HeaderHtml').text} #{doc.xpath('//Case/CaseHtml').text}"
      end
#      puts
#      puts "Content of #{file}, post-stripping: "
#      puts c.content

#      puts
#      puts

      if c.save
#        puts "Successfully imported: #{file}"
      else 
        puts "FAILED: #{file}"
        puts c.errors.full_messages.join("\n")
        puts
        puts
      end
    end
      Sunspot.commit_if_dirty
  end

  desc 'Send rotisserie invitations'
  task(:send_invites => :environment) do
    notification_invites = NotificationInvite.all(:conditions => {:sent => false, :resource_type => "RotisserieInstance"})

    notification_invites.each do |notification_invite|
      Notifier.deliver_rotisserie_invite_notify(notification_invite)
      notification_invite.update_attributes({:sent => true})
    end
  end

  desc 'Send cases list email'
  task(:send_cases_list_email => :environment) do
    CaseList.deliver_newly_added
  end
end
