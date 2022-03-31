import UIKit
import Kanna

final class Scraper {
    static let shared = Scraper()
    var awards        = [Award]()
    
    func getRecieptNumbers(URLStr: String, completion: @escaping (Result<(awards: [Award],footerText: String?, titleText: String?), Error>) -> Void) {
        let session = URLSession.shared
        let url = URL(string: URLStr)!
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            
            guard let self = self, let loadedData = data, error == nil else {
                completion(.failure(error!))
                return
            }

            let contents = String(data: loadedData, encoding: .utf8)!
                        
            do {
                let parsedHTML = try Kanna.HTML(html: contents, encoding: String.Encoding.utf8)
                let totalAwardsCount = parsedHTML.xpath("//div[@class ='etw-web']//tbody/tr/td[@headers = 'th01']").count
                let firstAwardNumberOfArray = self.getFirstAward(parsedHTML)
                
                for ix in 1...totalAwardsCount {
                    
                    let title = parsedHTML.xpath("//div[@class ='etw-web']//tr[\(ix)]/td[@headers = 'th01']").first?.text
                    let number = parsedHTML.xpath("//div[@class = 'etw-web']//tr[\(ix)]//span").first?.text
                    let description = parsedHTML.xpath("//div[@class ='etw-web']//tr[\(ix)]/td[2]/p[@class = 'mb-0']").first?.text
                    
                    switch ix {
                            
                        //特別獎, 特獎
                        case 1...2:
                            self.awards.append(Award(title: title, numbers: [Int(number ?? "資料錯誤")], description: description))
            
                        //case 3...8: 頭獎
                            
                        case 3...8:
                            self.awards.append(Award(title: title, numbers: firstAwardNumberOfArray, description: description))

                        default:
                            completion(.failure(ScrapeError.defaultBreak))
                    }
                }
                
                //標題
                let headerText = parsedHTML.xpath("//div[@class ='etw-web']//ul/li[1]").first?.text
                
                //footer
                let footerText = parsedHTML.xpath("//div[@class ='etw-web']//tfoot//td").first?.text
                
                //傳到view
                completion(.success((self.awards, footerText, headerText)))
            }
            catch {
                completion(.failure(ScrapeError.parseHTML))
            }
        }
        task.resume()
    }
    
    //頭獎 拼接字串
    func getFirstAward(_ parsedHTML: HTMLDocument) -> [Int] {
        let rhsTexts = parsedHTML.xpath("//div[@class ='etw-mobile']//tr[3]/td[2]/p[@class = 'etw-tbiggest mb-md-4']/span[@class = 'font-weight-bold etw-color-red']")
        let lhsTexts = parsedHTML.xpath("//div[@class ='etw-mobile']//tr[3]/td[2]/p[@class = 'etw-tbiggest mb-md-4']/span[@class = 'font-weight-bold']")
        var arr:[Int] = []
        
        for ix in 0..<rhsTexts.count {
            
            if let rhsText = rhsTexts[ix].text,
               let lhsText = lhsTexts[ix].text {
                
                arr.append(Int(lhsText + rhsText)!)
            }
        }
        return arr
    }
    
    
}

enum ScrapeError: Error {
   case title
   case footer
   case parseHTML
   case defaultBreak
}
