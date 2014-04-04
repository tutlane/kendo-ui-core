require 'selenium-webdriver'
require 'singleton'
require 'version'

class TelerikReleaseBot
    include Singleton

    attr_reader :driver

    def initialize
        @driver = Selenium::WebDriver.for(:firefox)
        @driver.navigate.to ADMIN_URL

        driver.find_element(:name, "txtEmail").send_keys ADMIN_RELEASE_UPLOAD_LOGIN
        driver.find_element(:name, "txtPassword").send_keys ADMIN_RELEASE_UPLOAD_PASS
        driver.find_element(:name, "btnLogin").click
    end

    def find(selector)
        driver.find_element(:css, selector)
    end

    def go_to_product_versions
        click_and_wait "Administration", "administration"
        click_and_wait "Product Versions", "product"
    end

    def click_and_wait(link, title)
        driver.find_element(:link, link).click
        wait_for_title(title)
    end

    def wait_for_title(title)
        Selenium::WebDriver::Wait.new(:timeout => 10).until { driver.title.downcase.start_with? title }
    end

    def fill_in(title, contents)
        element = driver.find_element(:xpath, "//a[text()='#{title}']/..//input")
        driver.execute_script 'arguments[0].focus()', element
        element.send_keys contents
        element.send_keys :tab
    end

    def quit
        driver.quit
    end
end

def upload_release_build(options)
    bot = TelerikReleaseBot.instance

    bot.go_to_product_versions

    bot.click_and_wait("Product Name", "product")
    #bot.driver.execute_script <<-SCRIPT
         #var masterTable = $find($telerik.$('[id$=\"_dgProducts\"]').attr('id')).get_masterTableView();
         #masterTable.filter("ProductName", "ui", Telerik.Web.UI.GridFilterFunction.Contains);
    #SCRIPT

    #bot.wait_for_title "product"

    #Thread.current.send :sleep, 3

    create_version(bot, options) 
    
end
def create_version(bot, options)
      bot.click_and_wait options[:product], "administration"
      bot.click_and_wait "Manage Versions", "administration"

      if defined? SERVICE_PACK_NUMBER
        bot.click_and_wait "New Minor","administration"
        fill_version_fields(bot)
        prepare_files(bot, options)  
      else
        bot.click_and_wait "New Major","administration"
        fill_version_fields(bot)
        prepare_files(bot, options)  
      end
end
def fill_version_fields(bot)
       bot.driver.execute_script "$('[id$=\"_txtMajorName\"]').val('#{VERSION_YEAR}.#{VERSION_Q}')"
       last_numbers = VERSION.split(".")[2]
       bot.driver.execute_script "$('[id$=\"_txtMinorName\"]').val('#{last_numbers}')"
       bot.driver.execute_script "$('[id$=\"_cbBeta\"]').prop('checked', true)"

       bot.find("[value='Save']").click
       bot.click_and_wait "Copy Files and Save", "administration"

end
def prepare_files(bot, options)
  #todo
  #bot.driver.execute_script "window.location = $('a:contains(\"commercial.zip\")').attr(\"href\")"

  #msi files
  if options[:msi]
    element = bot.driver.find_element(:xpath, "//a[contains(.,'commercial.msi')]")
    element.click

    options[:file_name] = options[:title] + ".msi"
    bot.driver.execute_script "$('[id$=\"_txtFileName\"]').val('#{options[:file_name]}')" 

    p "Setting filename..."
    p "#{options[:file_name]}"
    upload_file_and_go_back(bot, options)


    element = bot.driver.find_element(:xpath, "//a[contains(.,'trial.msi')]")
    element.click

    options[:file_name] = options[:title].sub! "commercial", "trial" + ".msi"
    bot.driver.execute_script "$('[id$=\"_txtFileName\"]').val('#{options[:file_name]}')" 

    upload_file_and_go_back(bot, options)

    options[:msi] = nil
  end
  
  #zip files
  element = bot.driver.find_element(:xpath, "//a[contains(.,'commercial.zip')]")
  element.click

  options[:file_name] = options[:title]  + ".zip"
  bot.driver.execute_script "$('[id$=\"_txtFileName\"]').val('#{options[:file_name]}')" 

  upload_file_and_go_back(bot, options)

  element = bot.driver.find_element(:xpath, "//a[contains(.,'trial.zip')]")
  element.click

  options[:file_name] = options[:title].sub! "commercial", "trial" + ".zip"
  bot.driver.execute_script "$('[id$=\"_txtFileName\"]').val('#{options[:file_name]}')" 

  upload_file_and_go_back(bot, options)
  
  #hotfix files
  if options[:vs_extension]
      element = bot.driver.find_element(:xpath, "//a[contains(.,'hotfix') and contains(.,'commercial')]")
      element.click

      file_name = options[:title]
      bot.driver.execute_script "$('[id$=\"_txtFileName\"]').val('#{file_name}.hotfix.zip')" 

      upload_file_and_go_back(bot, options)

      element = bot.driver.find_element(:xpath, "//a[contains(.,'hotfix') and contains (.,'trial')]")
      element.click

      file_name = options[:title].sub! "commercial", "trial"
      bot.driver.execute_script "$('[id$=\"_txtFileName\"]').val('#{file_name}.hotfix.zip')" 

      upload_file_and_go_back(bot, options)
  end
  #nuget files
  if options[:nuget]
      #element = bot.driver.find_element(:xpath, "//a[contains(.,'commercial.nupkg')]") - to replace after April 16th
      element = bot.driver.find_element(:xpath, "//a[contains(.,'NuGet') and contains(.,'commercial')]")
      element.click

      file_name = options[:title] 
      bot.driver.execute_script "$('[id$=\"_txtFileName\"]').val('#{file_name}.nupkg.zip')" 

      upload_file_and_go_back(bot, options)

      #element = bot.driver.find_element(:xpath, "//a[contains(.,'trial.nupkg')]") - to replace after April 16th
      element = bot.driver.find_element(:xpath, "//a[contains(.,'NuGet') and contains(.,'trial')]")
      element.click

      file_name = options[:title].sub! "commercial", "trial"
      bot.driver.execute_script "$('[id$=\"_txtFileName\"]').val('#{file_name}.nupkg.zip')" 

      upload_file_and_go_back(bot, options)
  end

  #installer files
  if options[:common_installer_complete]
    element = bot.driver.find_element(:xpath, "//a[contains(.,'ControlPanel')]")
    element.click

    options[:file_name] = "TelerikControlPanelSetup.KUI.Professional#{VERSION}.exe"
    bot.driver.execute_script "$('[id$=\"_txtFileName\"]').val('#{options[:file_name]}')" 

    upload_file_and_go_back(bot, options)
  end
  if options[:common_installer_mvc]
    element = bot.driver.find_element(:xpath, "//a[contains(.,'ControlPanel')]")
    element.click

    bot.driver.execute_script "$('[id$=\"_txtFileName\"]').val('TelerikControlPanelSetup.MVC.#{VERSION}.exe')" 

    upload_file_and_go_back(bot, options)  

    #element = bot.driver.find_element(:xpath, "//a[contains(.,'AspNetMvc')]") - to replace after April 16th
    element = bot.driver.find_element(:xpath, "//a[contains(.,'ASPNETMVC')]")
    element.click

    bot.driver.execute_script "$('[id$=\"_txtFileName\"]').val('TelerikUIForAspNetMvcSetup.#{VERSION}.exe')" 

    upload_file_and_go_back(bot, options)    
  end

end
def upload_file_and_go_back(bot, options)
  full_path = File.expand_path(options[:archive_path] + "/" + options[:file_name], File.join(File.dirname(__FILE__), ".."))
  p "#{full_path}"
  element = bot.driver.find_element(:xpath, "//input[contains(@id,'rdFileUploadfile0')]")
  element.send_keys(full_path)

  #p full_path

  p "msi uploaded"

  if options[:msi]
    #p full_path
    options[:file_name] = options[:file_name].sub! "msi", "xml"
    p "Setting xml filename..."
    p "#{options[:file_name]}"

    full_path = File.expand_path(options[:archive_path] + "/" + options[:file_name], File.join(File.dirname(__FILE__), ".."))

    p "#{full_path}"
    element = bot.driver.find_element(:xpath, "//input[contains(@id,'rdXMLConfigFileUploadfile0')]")
    element.send_keys(full_path)
    p "xml uploaded"   
  end
  #Thread.current.send :sleep, 10

  bot.find("[value='Save']").click

  p "Saving..."

  #Thread.current.send :sleep, 10

  bot.find("[value='GO TO FILE LIST']").click
end
def release_build_file_copy(release_build_config, name)
    if defined? SERVICE_PACK_NUMBER
        destination_folder_name = "Q#{VERSION_Q} #{VERSION_YEAR} SP#{SERVICE_PACK_NUMBER}"
    else
        destination_folder_name = "Q#{VERSION_Q} #{VERSION_YEAR}"
    end

    versioned_bundle_destination_path = File.join(RELEASE_ROOT, VERSION_YEAR.to_s, destination_folder_name)
    versioned_bundle_archive_path = File.join(ARCHIVE_ROOT, "Production")


    FileUtils.mkdir_p(versioned_bundle_destination_path)

    if release_build_config[:zip]
      build_path_and_copy \
      :destination =>  versioned_bundle_destination_path,
      :archive => versioned_bundle_archive_path,
      :vbd => versioned_bundle_name(name),
      :extension => ".zip"

    end
    if release_build_config[:msi]
      build_path_and_copy \
      :destination =>  versioned_bundle_destination_path,
      :archive => versioned_bundle_archive_path,
      :vbd => versioned_bundle_name(name),
      :extension => ".msi"

    end
    if release_build_config[:xml]
      build_path_and_copy \
      :destination =>  versioned_bundle_destination_path,
      :archive => versioned_bundle_archive_path,
      :vbd => versioned_bundle_name(name),
      :extension => ".xml"

    end
    if release_build_config[:nuget]
      build_path_and_copy \
      :destination =>  versioned_bundle_destination_path,
      :archive => versioned_bundle_archive_path,
      :vbd => versioned_bundle_name(name),
      :extension => ".nupkg.zip"
    end
    if release_build_config[:download_builder]
      build_path_and_copy \
      :destination =>  versioned_bundle_destination_path,
      :archive => versioned_bundle_archive_path,
      :static_name => "download-builder" 
      
    end
    if release_build_config[:demos]
      build_path_and_copy \
      :destination =>  versioned_bundle_destination_path,
      :archive => versioned_bundle_archive_path,
      :static_name => "online-examples.zip" 

    end
    if release_build_config[:common_installer]
      archive_file = File.join(WEB_INSTALLER_ROOT, "TelerikControlPanelSetup.exe")
      cp archive_file, File.join(versioned_bundle_destination_path, "TelerikControlPanelSetup.MVC.#{VERSION}.exe")
      cp archive_file, File.join(versioned_bundle_destination_path, "TelerikControlPanelSetup.KUI.Complete.#{VERSION}.exe") 

      archive_file = File.join(WEB_INSTALLER_ROOT, "TelerikUIForAspNetMvcSetup.exe")
      cp archive_file, File.join(versioned_bundle_destination_path, "TelerikUIForAspNetMvcSetup.#{VERSION}.exe")
    end

    return versioned_bundle_destination_path    
end
def build_path_and_copy(options)
   if options[:static_name]
    destination = File.join(options[:destination], options[:static_name])
    archive = File.join(options[:archive], options[:static_name])
   else
    destination = File.join(options[:destination], options[:vbd] + options[:extension])
    archive = File.join(options[:archive], options[:vbd] + options[:extension])
   end
   cp_r archive, destination
end

desc "Upload release builds"
task "release_builds:upload" do
    p "my task"
end