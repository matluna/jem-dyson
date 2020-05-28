import Foundation
class Settings {
    
    private init() {}
    public static let sharedInstance = Settings()
    
    public func getEnvironmentDetailsFor(environment:Environment) -> [String:String]{
        
        var result : [String:String]!
        var resourceGroup : String!
        var saveTransactionDetailsAPIkey : String!
        var saveTransactionDataAPIkey : String!
        
        switch(environment){
        case .PROD:
            resourceGroup = "jem-reconciliation-prd-function01"
            saveTransactionDetailsAPIkey = "sVeOU83jWKiwxASlC/VIVDvxpiAn/taHkmHqBIKz02WA1mMUTPnR5Q=="
            saveTransactionDataAPIkey = "s4UmE0JtsmZm4YkUKwxilFUcY6a3oD6FJuuy7Qjf4/ABAecX0WQOgQ=="
            break
        case .TESTPROD:
            resourceGroup = "jem-reconciliation-qap-function01"
            saveTransactionDetailsAPIkey = "IqXlpTMItYuQbexxmX9kjp4RA4EvQSISYIGlRynn/tWQoh72HpRU0g=="
            saveTransactionDataAPIkey = "sSXzIk0OjKSKFatEa24jRJ0dNa4qg9nmgl22zA9Xcs3I76HvcEIibQ=="
            break
        case .TESTSYS:
            resourceGroup = "jem-reconciliation-qas-function01"
            saveTransactionDetailsAPIkey = "aYLm4dgQp6gtbrtXO/zYXlou/LAvOK6UBFznR828nY6HlJolpxkduA=="
            saveTransactionDataAPIkey = "GF6pAIOX0nuYFIXG54OOxOUgeY4gjgbyo1eGNAUyOmZzzTd/g7yuqQ=="
            break
        case .DEVDEV:
            resourceGroup = "jem-reconciliation-dev-function01"
            saveTransactionDetailsAPIkey = "5BM5kyCcAmLn9vwdUJhhBDUodfXzRUacczcQ7o2Ac09RpA0EKljvcg=="
            saveTransactionDataAPIkey = "burwnsbmTv53bu0SBY8pT0UUhqiLBuMWNjrMC6ywJcv7FzWWDsvahw=="
            break
        case .DEVPROD:
            resourceGroup = "jem-reconciliation-devp-function01"
            saveTransactionDetailsAPIkey = ""
            saveTransactionDataAPIkey = "goZw7gDLnOkzRczrrLiZFqQ2SX2JiXuJnDCzBK/gOuGhNRkQwdpJpw=="
            break
        case .DEVSYS:
            resourceGroup = "jem-reconciliation-devs-function01";
            saveTransactionDetailsAPIkey = "5BM5kyCcAmLn9vwdUJhhBDUodfXzRUacczcQ7o2Ac09RpA0EKljvcg=="
            saveTransactionDataAPIkey = "NLdyKeEABLNx9TauvF1ZFAWynrrad0IPXeVBrwF6FghfGFca8IaPZQ=="
            break
        }
        
        result = ["resourceGroup":resourceGroup,
                  "saveTransactionDetailsAPIkey":saveTransactionDetailsAPIkey,
                  "saveTransactionDataAPIkey":saveTransactionDataAPIkey]
        
        return result
        
    }
    
}
