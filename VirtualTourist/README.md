#Virtual Tourist Modified

In this version of Virtual Tourist user can choose as many pins as he wants on the map and corresponding images from these locations will be downloaded in an album, he can select and delete photos from his collection and he can select an image to share it along with its location with anyone, he can also send the image after editing it by adding text or applying filters on it

#App Features 

1- Download and save Albums of Flickr public photos to corresponding pins 
2- Selecting and Deleting unwanted photos 
3- Editing photos by adding text that is responsive to font color   and size change, as well as hand gestures 
4- Editing photos by adding fliters using Apple's  built in Core Image functionality  
5- Sharing the selected photo with others along with a google maps url of its location 

#Implementation 

1- Map View Controller 
User can drop as many pins on the map as he wants, he can also delete pins.
When User taps on a certain pin it takes him to the next view controller 

2- Photo Album View Controller 
A detailed map view and a collection view of downloaded photos will be loaded with this view controller, user can in this view controller choose collection of photos to delete them by tapping on "Select" button, he can also download a new collection of photos by tapping "New collection" button, or he can tap on a photo which will lead him to next view controller 

3- Photo View Controller 
In this view controller user can edit the image he selected by adding text, changing text colors, changing text font by dragging a slider and by addding fliters to the image. user can also share the photo along with a google maps URL location of the photo to others 

#Requirements 

Swift 10.0 
Xcode 11 



