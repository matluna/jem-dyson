import Foundation
public class BlobDataModel {
    public var blobFolder: String
    public var photoName: String
    
    public init (blobFolder: String, photoName: String){
        self.blobFolder = blobFolder
        self.photoName = photoName
    }
}
