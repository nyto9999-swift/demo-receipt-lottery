//
//  ViewController.swift
//  ReceiptLottery
//
//  Created by 宇宣 Chen on 2022/3/30.
//

import UIKit
import Kanna

class ViewController: UIViewController {
    var firstPrize = [[Character]]()
    var extraSpecialPrize = [Character]()
    var specialPrize = [Character]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getHTML(URLStr: "https://invoice.etax.nat.gov.tw/index.html")
    }
    
    func getHTML(URLStr: String) {
        let session = URLSession.shared
        let url = URL(string: URLStr)!
        let task = session.dataTask(with: url) { data, response, error in
            // Check whether data is not nil
            guard let loadedData = data else { return }
            // Load HTML code as string
            let contents = String(data: loadedData, encoding: .utf8)
            guard let contents = contents else { return }

            do {
                let parsedHTML = try Kanna.HTML(html: contents, encoding: String.Encoding.utf8)
                
                self.scrapeThisMonthNumber(parsedHTML)
                
            }
            catch {
                print(fatalError())
            }
        }
        task.resume()
    }
    
    func scrapeThisMonthNumber(_ parsedHTML: HTMLDocument) {
        
        for ix in 1...3 {
            switch ix {
                    
                //特別獎
                case 1:
                    let receiptNumber = parsedHTML.xpath("//div[@class = 'etw-web']//tr[\(ix)]//span")
                    extraSpecialPrize = Array(receiptNumber.first!.text!)
                    
                //特獎
                case 2:
                    let receiptNumber = parsedHTML.xpath("//div[@class = 'etw-web']//tr[\(ix)]//span")
                    specialPrize = Array(receiptNumber.first!.text!)
                    
                //頭獎
                case 3:
                    let lastThreeNumbers = parsedHTML.xpath("//div[@class ='etw-mobile']//tr[\(ix)]/td[2]/p[@class = 'etw-tbiggest mb-md-4']/span[@class = 'font-weight-bold etw-color-red']")
                    let restOfNumbers = parsedHTML.xpath("//div[@class ='etw-mobile']//tr[\(ix)]/td[2]/p[@class = 'etw-tbiggest mb-md-4']/span[@class = 'font-weight-bold']")
                    
                    for n in 0..<lastThreeNumbers.count {
                        let number = Array(restOfNumbers[n].text! + lastThreeNumbers[n].text!)
                        firstPrize.append(number)
                    }

                default:
                    print("something wrong")
                    break
            }
        }
//        for firstPrize in firstPrize {
//            print(firstPrize)
//        }
//        for extraSpecialPrize in extraSpecialPrize {
//            print(extraSpecialPrize)
//        }
//        for specialPrize in specialPrize {
//            print(specialPrize)
//        }
//
        
       
        
         
    }
    
    
}


