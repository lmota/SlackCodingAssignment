//
//  FileManagerExtension.swift
//
//  Created by Slack Candidate on 2024-06-14.
//

import Foundation

extension FileManager {
    
    /*
     * Make writable copy of the destination file name and copy contents from original file to destination file for the first time.
     * Following times, returns the file url for the destination file
     */
    func makeWritableCopy(named destFileName: String, ofResourceFile originalFileName: String) throws -> URL {
        // Get Documents directory in app bundle
        guard let documentsDirectory = self.urls(for: .documentDirectory, in: .userDomainMask).last else {
            fatalError("No document directory found in application bundle.")
        }

        // Get URL for dest file (in Documents directory)
        let writableFileURL = documentsDirectory.appendingPathComponent(destFileName)

        // If destination file doesn’t exist yet
        if (try? writableFileURL.checkResourceIsReachable()) == nil {

            // Get original (unwritable) file’s URL
            guard let originalFileURL = Bundle.main.url(forResource: originalFileName, withExtension: nil) else {
                fatalError("Cannot find original file “\(originalFileName)” in application bundle’s resources.")
            }

            // Get original file’s contents
            let originalContents = try Data(contentsOf: originalFileURL)

            // Write original file’s contents to dest file
            try originalContents.write(to: writableFileURL, options: .atomic)
            Logger.logInfo("Made a writable copy of file “\(originalFileName)” in “\(documentsDirectory)\\\(destFileName)”.")

        } else { // Dest file already exists
            let contents = try String(contentsOf: writableFileURL, encoding: String.Encoding.utf8)
            Logger.logInfo("File “\(destFileName)” already exists in “\(documentsDirectory)”.\nContents:\n\(contents)")
        }

        // Return destination file URL
        return writableFileURL
    }
    
    /*
     * Fetch the file url for path from documents directory
     */
    func fileURL(for path: String, extension: String) -> URL {
        let directoryURL = self.urls(for: .documentDirectory, in: .userDomainMask).first
        return URL(fileURLWithPath: path, relativeTo: directoryURL).appendingPathExtension(Constants.denyListFileExtension)
    }
    
}
