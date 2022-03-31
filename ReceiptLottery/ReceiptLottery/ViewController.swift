import UIKit
import Kanna

class ViewController: UIViewController {

    var awards = [Award]()
    let customFont:UIFont = UIFont.init(name: "AppleSDGothicNeo-Bold", size: 40.0)!
    
    lazy var textField:UITextField = {
        let textField = UITextField(frame: CGRect(x: view.frame.size.width / 2 - 140,
                                                  y: view.frame.size.height / 5,
                                                  width: 280,
                                                  height: 80))
        textField.backgroundColor          = .lightGray.withAlphaComponent(0.4)
        textField.borderStyle              = .roundedRect
        textField.clearButtonMode          = .whileEditing
        textField.font                     = customFont
        textField.textColor                = .lightGray
        
        return textField
    }()
    
    //title, desc, number of labels
    var label = { () -> UILabel in
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints             = false
        label.widthAnchor.constraint(equalToConstant: 280).isActive = true
        label.numberOfLines                                         = 0
        label.lineBreakMode                                         = .byWordWrapping
        return label
    }

    lazy var infoLabel:UILabel = {
        let label = UILabel(frame: CGRect(x: view.frame.size.width / 2 - 140, y: view.frame.size.height / 5 - 80 - 10, width: 280, height: 80))
        label.textAlignment = .center
        label.font          = customFont
        return label
    }()
     
    lazy var footerLabel:UILabel = {
        let label = UILabel(frame: CGRect(x: 5, y: view.frame.size.height - 40 - 10, width: view.frame.width - 10, height: 40))
        label.textAlignment = .center
        label.font          = UIFont.init(name: "AppleSDGothicNeo-light", size: 16.0)!
        return label
    }()
    
    lazy var titleLabel    = label()
    lazy var awardLabel    = label()
    lazy var numberLabel   = label()
    lazy var descLabel     = label()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let URLStr = "https://invoice.etax.nat.gov.tw/index.html"
        Scraper.shared.getRecieptNumbers(URLStr: URLStr,completion: { [weak self] result in
            guard let self = self else { return }

            switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.awards = response.awards
                        self.footerLabel.text = response.footerText
                        self.titleLabel.text = response.titleText
                    }
                case .failure(let error):
                    print(error)
            }
        })
        setupViews()
        setupConstraints()
    }
    
    func setupViews(){
        numberLabel.font         = customFont
        numberLabel.textColor    = .systemOrange
        titleLabel.textAlignment = .center
        
        view.addSubview(infoLabel)
        view.addSubview(titleLabel)
        view.addSubview(awardLabel)
        view.addSubview(numberLabel)
        view.addSubview(descLabel)
        view.addSubview(textField)
        view.addSubview(footerLabel)
        textField.delegate = self
    }
    
    func setupConstraints() {

        titleLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 10).isActive = true
        awardLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
        numberLabel.topAnchor.constraint(equalTo: awardLabel.bottomAnchor, constant: 10).isActive = true
        descLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 10).isActive = true
        
        titleLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        awardLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        numberLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        descLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        
        titleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        awardLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        numberLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        descLabel.heightAnchor.constraint(equalToConstant: 80).isActive = true
    }
    
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        
        if textField.text?.count == 8 {
            self.textField.textColor = .darkGray
            
            guard let textFieldText = textField.text, textFieldText.count == 8 else {
                self.textField.placeholder = "請輸入八個數字"
                self.numberLabel.text = ""
                self.descLabel.text = ""
                return
            }
            
            let userInput = Int(textFieldText)
            var isNotAllCorrect = true
            
            for ix in 0...2 {
                
                for number in awards[ix].numbers {
                    
                    //號碼全對，特別獎，特獎，頭獎
                    if userInput == number {
                        
                        DispatchQueue.main.async {
                            self.awardLabel.text = self.awards[ix].title
                            self.numberLabel.text = "\(number ?? 0)"
                            self.descLabel.text = self.awards[ix].description
                            self.infoLabel.text = "恭喜中獎"
                            self.textField.textColor = .systemOrange
                        }
                        isNotAllCorrect = false
                    }
                }
            }
            
            if isNotAllCorrect {
                let firstAwardNumbers = awards.filter { $0.title == "頭獎"}.first!.numbers
                var firstAwardDictionary = [Int:Int]()
                
                //頭獎有三組號碼，查看是否中 二獎，三獎，肆獎，五獎，六獎
                for (index, receiptNumber) in firstAwardNumbers.enumerated() {
                    var correctNumbers = 0
                    var cReceiptNumber = receiptNumber
                    var cUserInput = userInput
                    
                    while (cUserInput ?? 0) % 10 == (cReceiptNumber ?? 0) % 10 {
                        
                        cUserInput! /= 10
                        cReceiptNumber! /= 10
                        correctNumbers += 1
                        
                    }
                    firstAwardDictionary[index] = correctNumbers
                }
                
                //取出最大獎
                let biggestNumber = firstAwardDictionary.values.max()!
                let bingoIndex = firstAwardDictionary.first(where: { $0.value == biggestNumber})?.key
                guard let bingoIndex = bingoIndex else { return }
                
                //中獎
                if biggestNumber >= 3 {
                    let award = self.awards.first(where: {$0.description!.contains("中獎號碼末\(biggestNumber)")})
                    guard let award = award else {
                        self.titleLabel.text = "系統錯誤，有bug"
                        return
                    }
                    DispatchQueue.main.async {
                        self.awardLabel.text = award.title
                        self.numberLabel.text = "\(String(describing: award.numbers[bingoIndex]!))"
                        self.descLabel.text = award.description
                        self.infoLabel.text = "恭喜中獎"
                    }
                }
                //沒有中獎
                else {
                    self.infoLabel.text = "沒中獎"
                    self.awardLabel.text = ""
                    self.numberLabel.text = ""
                    self.descLabel.text = ""
                }
            }
        }
        else {
            self.textField.textColor = .lightGray
        }
    }
    
}



