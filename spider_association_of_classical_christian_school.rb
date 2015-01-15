#Author: Shuddhashil Ray
#Script : Ruby
#Description : Web Crawler for Association of Classical and Christian Schools
#Source : http://www.accsedu.org/members--by-state/member-schools
#Date : 15-January-2015 8:40PM IST

require 'rubygems'
require 'net/http'
require 'nokogiri'
require 'fileutils'
require 'csv'
require 'pp'

class String
  def extract_school_info s1, s2
    self[/#{Regexp.escape(s1)}(.*?)#{Regexp.escape(s2)}/m, 1]
  end
end

def get_csv_row state_name,school_info
	[state_name,school_info["name"],school_info["email"],school_info["web_address"],school_info["contact"],school_info["address_and_phone_number"],school_info["students"]]
end

uri = URI.parse("http://www.accsedu.org")
http = Net::HTTP.new(uri.host, uri.port)
http.start do |connection|
	#Fetch the Starting Page
	request = Net::HTTP::Get.new("/members--by-state/member-schools")
	response = connection.request(request)
	cookies = response.response['set-cookie'] #storing the Cookie to be sent in subsequent requests
	member_schools_doc = Nokogiri::HTML(response.body)
	schools_information = []
	CSV.open(File.join(File.dirname(__FILE__),"school_info.csv"), "w") do |csv|
		csv << ["STATE", "SCHOOL_NAME", "EMAIL", "WEB_ADDRESS","CONTACT_INFO","ADDRESS_AND_PHONE_INFO","STUDENTS_INFO"]
		#Parse the Xpath we need for State List Anchors
		member_schools_doc.xpath('//div[@id="ctl00_ContentBlock_home_ctl00_ctl00_ctl02_ctl08_wContent"]//a[@class="ews_cb_href_properties"]').each do |nodeset|
			state_url = nodeset.attributes["href"].value #Gets the URL of the State School Page
			state_name = nodeset.text.strip #Gets the State Name
			#Fetching Each State School Page, note there are redirects on these links, so we need to handle redirects too!
			state_page_rquest = Net::HTTP::Get.new(state_url)
	    state_page_rquest['Cookie'] = cookies
	    state_page_response = connection.request(state_page_rquest)
	    code = state_page_response.code
			while code=="302"
				state_page_rquest = Net::HTTP::Get.new(state_page_response['location'])
				state_page_rquest['Cookie'] = cookies
				state_page_response = connection.request(state_page_rquest)
				code = state_page_response.code
			end
	    state_page_doc = Nokogiri::HTML(state_page_response.body)
	    school_info_in_state ={}
	    current_index = 0
	    previous_index = nil
	    puts "---- Parsing State : #{state_name} -------"
			state_page_doc.xpath('//div[@id="ctl00_ContentBlock_home_ctl00_ctl00_ctl01_ctl01_wContent"]//a').each do |contentset|
				value = contentset.attributes["href"].value rescue ""
				if value.start_with?("http") and !contentset.text.empty?
					xpath_of_node = Nokogiri::CSS.xpath_for contentset.css_path
					school_info_in_state["#{current_index}"] = {"name"=>contentset.text,"web_address"=>value}
					previous_index = current_index
					current_index = current_index+1
				elsif value.start_with?("mailto")
					school_info_in_state["#{previous_index}"]["email"] = value.to_s.gsub("mailto:",'') if !previous_index.nil?
				end
			end
			#At this point of time we have obtained school name, web address and email
			#Getting the raw html content to be parsed now.
			raw_html = state_page_doc.xpath('//div[@id="ctl00_ContentBlock_home_ctl00_ctl00_ctl01_ctl01_wContent"]').inner_text
			#For rest of the info on School Document - Grade-Students Number Info, Contact Info, Address
			#Note : the below function takes two elements at a time, previous and current, therefore for the last element we need to do it separately. 
			school_count = school_info_in_state.count - 1
			school_info_in_state.each do |key,value|
				if key.to_i != 0
					prev_school_name = school_info_in_state["#{((key.to_i) -1)}"]["name"]
					currrent_school_name = school_info_in_state["#{key}"]["name"]
					info = raw_html.extract_school_info(prev_school_name,currrent_school_name).to_s
					begin
						school_info_in_state["#{((key.to_i) -1)}"]["students"] = info.include?("Grades:") ? info[(info.index("Grades:")+7)..((info.index("students)")+9)||info.length)].to_s.lstrip.rstrip.gsub(/\n/, " ").gsub(/\s+/, ' ') : ""
						if info.include?("Contacts:")
							school_info_in_state["#{((key.to_i) -1)}"]["contact"] = info[(info.index("Contacts:")+9)..(info.index("Grades:") || info.length)].to_s.lstrip.rstrip.gsub(/\n/, " ").gsub(/\s+/, ' ').split("DOM").join(" ")
						elsif info.include?("Contact:")
							school_info_in_state["#{((key.to_i) -1)}"]["contact"] = info[(info.index("Contact:")+8)..(info.index("Grades:") || info.length)].to_s.lstrip.rstrip.gsub(/\n/, " ").gsub(/\s+/, ' ').split("DOM").join(" ")
						else
							school_info_in_state["#{((key.to_i) -1)}"]["contact"] = ""
						end
						school_info_in_state["#{((key.to_i) -1)}"]["address_and_phone_number"] = info[0..(info.index("Email")||info.index("Contact:")||info.index("Contacts:")||info.index("Grades:"))].to_s.lstrip.rstrip.gsub(/\n/, " ").gsub(/\s+/, ' ')
						csv << get_csv_row(state_name,school_info_in_state["#{((key.to_i) -1)}"])
					rescue => e
					end
				end
			end
			#Now for the last school in the document
			prev_school_name = school_info_in_state["#{school_count}"]["name"]
			currrent_school_name = "Alphabetical List" #dummy name!
			info = raw_html.extract_school_info(prev_school_name,currrent_school_name).to_s
			begin
				school_info_in_state["#{school_count}"]["students"] = info.include?("Grades:") ? info[(info.index("Grades:")+7)..((info.index("students)")+9)||info.length)].to_s.lstrip.rstrip.gsub(/\n/, " ").gsub(/\s+/, ' ') : ""
				if info.include?("Contacts:")
					school_info_in_state["#{school_count}"]["contact"] = info[(info.index("Contacts:")+9)..(info.index("Grades:") || info.length)].to_s.lstrip.rstrip.gsub(/\n/, " ").gsub(/\s+/, ' ').split("DOM").join(" ")
				elsif info.include?("Contact:")
					school_info_in_state["#{school_count}"]["contact"] = info[(info.index("Contact:")+8)..(info.index("Grades:") || info.length)].to_s.lstrip.rstrip.gsub(/\n/, " ").gsub(/\s+/, ' ').split("DOM").join(" ")
				else
					school_info_in_state["#{school_count}"]["contact"] = ""
				end
				school_info_in_state["#{school_count}"]["address_and_phone_number"] = info[0..(info.index("Email")||info.index("Contact:")||info.index("Contacts:")||info.index("Grades:"))].to_s.lstrip.rstrip.gsub(/\n/, " ").gsub(/\s+/, ' ')
				csv << get_csv_row(state_name,school_info_in_state["#{school_count}"])
			rescue => e
			end
			#break
		end
	end #End of FasterCSV write!
end#End of HTTP Connection
