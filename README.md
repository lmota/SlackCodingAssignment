# SlackCodingAssignment
Create an app to search for slack employees

# Search Slack Employees App
==========================================
   Built an iOS app in Swift using UIKit to search Slack employees. The app supports online as well as offline mode.
   
  ## Build tools & versions used
  Xcode 14.1, deployment target - iOS 16.1
     
  ## Steps to run the app
  1. Launch the app using xcode with target as any iOS simulator or an iOS device.
  2. Upon launch, Search Employees screen appears with a search bar.
  3. Search for employees - display name or userid for e.g. "Brooklyn" (display name) or "bhuffman" (userid)
  4. Notice that if the search term is valid, it will fetch the Slack employees and they will be rendered in the tableview below.
  5. If search term is equal to the value available in the denylist.txt, alert message pops up and no api call is made.
  6. If search term (not already present in the deny list), yields no results then the alert message pops up and the search term is written into the readWrite version of the denylist file into the Documents directory as the main bundle with provided denylist.txt is read only.
  7. If the same search term as step#6 is typed into the search bar again then invalid search term alert message should appear.
  8. If the device does not have network connectivity then the app support offline mode and displays the last successfull result to begin with.
  9. App further supports searching in the offline mode. This was achieved by fetching all the slack employees at the launch time and then storing these slack employees onto the document directory. Given the time constraint, i chose this approach. If i had more time or in the real world scenario with large data, all slack employees api should be paginated and we would have only fetched first page.
  
  ## What areas of the app did you focus on?
  1. I primarily focused on the app's architecture. Designed the app using MVVM-C design pattern. 
  2. Ensured the app is responsive and there is no lag while fetching the data from Slack's search api'
  3. Ensured that I have met all the requirements that were listed in the take home project questionaire.
  4. Added the Unit tests for the business logic of the app, primarily the view model.
  5. Focused on providing a pleasant UI for the given problem.
  6. Ensured the code is readable, follows a consistent coding style.
  7. Provided utilites where necessary like logger, various extensions for imageview, url request, alert view controller etc.
  8. Implemented the in memory image caching using NSCache.
  9. Provided localization for English language for the app.
  1o. Implemented bonus requirements for supporting app in the offline mode. In addition to showing the last successfull search result, i also supported search in offline mode.
  12. I have also, implemented the parsing from a mock response file provided for unit tests.

  
  ## What was the reason for your focus? What problems were you trying to solve?
  I would always like to ensure that the app that I implement uses a correct design pattern, is functional and meets all the requirements, has a decent UI and business logic has been unit tested. This way I can always complete the minimum viable product first and then iterate upon it as necessary.
   
  
  ## How long did you spend on this project?
  I spent approximately 6-7 hours in total (split over two days)
  
  ## Did you make any trade-offs for this project? What would you have done differently with more time?
    1. I would have provided the list view with further details about each employee.
    2. I would have tested the app under low memory conditions, profiling, checking for leaks etc.
    3. I would have added additional unit tests.
  
  ## What do you think is the weakest part of your project?
  I feel like the weakest part of my project would be the UI. I could have worked to improvise that with more details and custom UI elements if there was more time. 
  
  
  ## Additional information?
  
Following would be additional information I would like to inform:
  

Coding language
===============
Swift 5


APIs used for fetching image data
=================================
The data is fetched asynchronously using Combine framework.
NSCache is used for Image caching. 
JsonDecoder for decoding the data.
DataModels were 'Codable'.
Used UITableViewDiffableDatasource and applied a snapshot of the model changes to this diffable datasource.


Features
========
Following are the features that were implemented:

1. Present a search bar using UISearch bar to let user search for Slack employees by display name and userId. Upon entering search text, app displays the Slack employees.
2. Each item in the search result displays the employee's avatar image, display name and user id.
3. Supported the app in online as well as offline mode.
4. Upon entering another search the employee list animates and refreshes.
5. Used Grand central discpatch for multi threading. Ensuring that the UI related tasks are performed on the main thread.
6. Ensured that the logging is only used in DEBUG scheme and not for RELEASE, by creating a logger utility.
7. Provided localization for English language.
8. Used MVVM-C design pattern.
9. Used programatic ways of painting the UI using Autolayouts for laying UI elements.
10. Added test cases for the view model to test the core business logic.


App architecture:
================
1. App has been designed to use MVVM-C design pattern. The reason for going with this over MVC is that it helps compartmentalize the code to have all the business logic in view models and UI presentation in the views and view controllers.
2. Used various extensions to make few commonly used functions more reusable.
3. Provided localization, logging and unit test support.
4. Used Multi-threading using Grand Central Dispatch.
5. Used Autolayouts for laying the UI elements.
6. Used in memory Image caching using NSCache.
8. Used JsonDecoder to decode the response. Data Models were 'Decodable'.
9. Used Combine framework to fetch data
10. Used Diffable Data source for UITableview



Reference
==========
Apple documentation and questionaire for the take home project


Unit Tests
==========
Added the basic unit testing target. Implemented unit tests for the view model. Would have done more negative unit test cases, if had more time.


  



--------------------
Lopa Dharamshi (Mota)

