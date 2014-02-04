# Load the Rails application.
require File.expand_path('../application', __FILE__)
require File.expand_path('../h2o_routes_configurator/routes_upgrader', __FILE__)
# Initialize the Rails application.
H2o2::Application.initialize!
H2o2::Application.routes.disable_clear_and_finalize = true
eval(Rails::Upgrading::RoutesUpgrader.generate_h2o_routes)
