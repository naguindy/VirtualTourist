//
//  DataController.swift
//  VirtualTourist
//
//  Created by Noha on 31.10.19.
//  Copyright © 2019 udacity. All rights reserved.
//

import Foundation
import CoreData

enum DataError: Error {
    case errorStatusCode
    case invalidData
}
class DataController{

    let persistentContainer : NSPersistentContainer
    var viewContext :NSManagedObjectContext{
        return persistentContainer.viewContext
    }

    init(modelName: String){
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (()-> Void)? = nil){
        persistentContainer.loadPersistentStores{ storedescription, error in
            guard error == nil else{
                fatalError(error!.localizedDescription)
            }
            completion?()

        }
    }

    func loadPhotos(from pin: Pin, at page: Int, onCompletion: @escaping (Result<[Photo], Error>) -> Void) {
        do {
            // 1. Fetch from database
            let fetchRequest : NSFetchRequest<Photo> = Photo.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "pin == %@ && page == %d", pin, page)
            let result = try viewContext.fetch(fetchRequest)
            // 2. If not found, fetch from Flickr
            if result.isEmpty {
                fetchImagesFromFlickr(pin: pin, page: page) { flickr in
                    switch flickr {
                        case let .success(urls):
                            var photos: [Photo] = []
                            for url in urls {
                                let photo = Photo(context: self.viewContext)
                                photo.url = url
                                photo.pin = pin
                                photo.page = Int32(page)
                                photos.append(photo)
                            }
                            try? self.viewContext.save()
                            onCompletion(.success(photos))
                        case let .failure(error):
                            onCompletion(.failure(error))
                    }
                }
            } else {
                onCompletion(.success(result))
            }
        } catch {
            onCompletion(.failure(error))
        }
    }

    func delete(photos: [Photo]) {
        for item in photos {
            viewContext.delete(item)
        }
        try? viewContext.save()
    }
}

//MARK: - Network
extension DataController {
    private func bboxString(longitude: Double, latitude: Double) -> String {
        let minLon = max(longitude - Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.0)
        let minLat = max(latitude - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
        let maxLon = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
        let maxLat = min(latitude + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
        return "\(minLon),\(minLat), \(maxLon), \(maxLat)"
    }

    private func flickrURL(parameters: [String: Any]) -> URL{
        var components = URLComponents()
        components.scheme = Flickr.APIScheme
        components.host = Flickr.APIHost
        components.path = Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        for (key, value) in parameters{
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }

    private func fetchImagesFromFlickr(pin: Pin,
                                       page: Int,
                                       onCompletion: @escaping (Result<[String], Error>) -> Void) {

        let boundingBox = bboxString(longitude: pin.longitude, latitude: pin.latitude)
        let methodParameters: [String: Any] = [
            Flickr.FlickrParameterKeys.Method: Flickr.FlickrParameterValues.SearchMethod,
            Flickr.FlickrParameterKeys.APIKey: Flickr.FlickrParameterValues.APIKey,
            Flickr.FlickrParameterKeys.BoundingBox: boundingBox,
            Flickr.FlickrParameterKeys.SafeSearch: Flickr.FlickrParameterValues.UseSafeSearch,
            Flickr.FlickrParameterKeys.Extras: Flickr.FlickrParameterValues.MediumURL,
            Flickr.FlickrParameterKeys.Format: Flickr.FlickrParameterValues.ResponseFormat,
            Flickr.FlickrParameterKeys.NoJSONCallback: Flickr.FlickrParameterValues.DisableJSONCallback,
            Flickr.FlickrParameterKeys.PerPage: Flickr.FlickrParameterValues.PerPage,
            Flickr.FlickrParameterKeys.Page: String(page),
        ]

        let session = URLSession.shared
        let url = flickrURL(parameters: methodParameters)

        let request = URLRequest(url: url)
        let task = session.dataTask(with: request){ data, response, error in
            if let error = error {
                onCompletion(.failure(error))
                return
            }

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                statusCode >= 200 && statusCode <= 299 else {
                    onCompletion(.failure(DataError.errorStatusCode))
                    return
            }

            /* GUARD: Was there any data returned? */
            guard let data = data else {
                onCompletion(.failure(DataError.invalidData))
                return
            }

            do {
                guard let parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] else {
                    onCompletion(.failure(DataError.invalidData))
                    return
                }

                guard  let photosDictionary = parsedData[Flickr.FlickrResponseKeys.Photos] as? [String: AnyObject] else{
                    onCompletion(.failure(DataError.invalidData))
                    return
                }

                guard let photoArray = photosDictionary[Flickr.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else{
                    onCompletion(.failure(DataError.invalidData))
                    return
                }

                guard !photoArray.isEmpty else {
                    onCompletion(.failure(DataError.invalidData))
                    return
                }

                var result: [String] = []
                for item in photoArray{
                    if let imageURL = item[Flickr.FlickrResponseKeys.MediumURL] as? String {
                        result.append(imageURL)
                    }
                }
                onCompletion(.success(result))
            } catch{
                onCompletion(.failure(DataError.invalidData))
                return
            }
        }
        task.resume()
    }
}
