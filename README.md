## Web Crawler for Association of Classical and Christian Schools

### This is a simple Ruby script to crawl the School information state-wise
- Source http://www.accsedu.org/members--by-state/member-schools
- The script crawls over each of the state from Alabama to Wyoming and retrives the Schools Data into a generated CSV

### How to run the program
 - Ruby 1.9.3
 - Nokogiri 1.6.5
 - `$> ruby spider_association_of_classical_christian_school.rb`
 
### Know-How
- To begin with the State-Pages for school e.g http://www.accsedu.org/members--by-state/alabama-members are not consistent with the HTML DOM structure and CSS.
- There are State-Pages for school which are not the same as others (the way HTML DOM structuring is done).
- Therefore it was a challenge to parse such pages where the HTML DOM is not consistent.
- Redirects were handled for the School Pages by the Script
- The Script can generate a CSV file containing Headers -  ["STATE", "SCHOOL_NAME", "EMAIL", "WEB_ADDRESS","CONTACT_INFO","ADDRESS_AND_PHONE_INFO","STUDENTS_INFO"]
- Sample row from the CSV generated looks like this : 
  * `Alabama	|| Bayshore Christian School	|| pmckee@bayshorechristian.org	|| http://www.bayshorechristian.org/	|| Mrs. Pam McKee, Headmaster : 10/04 - MemberG	|| 23050 US Hwy 98, Fairhope, AL  36532(251) 929-0011  FAX: (251) 928-0149E	|| K-10 (161 students)`
