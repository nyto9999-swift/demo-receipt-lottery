import UIKit
import Kanna

class ViewController: UIViewController {

    var awards = [Award]()
    var titleText:String = ""
    var footerText:String = ""
    let customFont:UIFont = UIFont.init(name: "AppleSDGothicNeo-Bold", size: 40.0)!
    
    lazy var textField:UITextField = {
        let textField = UITextField(frame: CGRect(x: view.frame.size.width / 2 - 140,
                                                  y: view.frame.size.height / 5,
                                                  width: 280,
                                                  height: 80))
        textField.backgroundColor          = .lightGray
        textField.borderStyle              = .roundedRect
        textField.clearButtonMode          = .whileEditing
        textField.font                     = customFont
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
    lazy var subTitleLabel = label()
    lazy var numberLabel   = label()
    lazy var descLabel     = label()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let URLStr = "https://invoice.etax.nat.gov.tw/index.html"
        Scraper.shared.getRecieptNumbers(URLStr: URLStr,completion: { [weak self] result in
            switch result {
                case .success(let response):
                    self?.awards = response.awards
                    self?.footerText = response.footerText
                    self?.titleText = response.titleText
                    
                case .failure(let error):
                    print(error)
            }
        })
    }
    override func viewDidLayoutSubviews() {
        setupViews()
        setupConstraints()
    }
    
    func setupViews(){
        numberLabel.font         = customFont
        numberLabel.textColor    = .systemOrange
        titleLabel.textAlignment = .center
        
        //wait for asyn function
        footerLabel.text = footerText
        titleLabel.text  = titleText
        
        view.addSubview(infoLabel)
        view.addSubview(titleLabel)
        view.addSubview(subTitleLabel)
        view.addSubview(numberLabel)
        view.addSubview(descLabel)
        view.addSubview(textField)
        view.addSubview(footerLabel)
        textField.delegate = self
    }
    
    func setupConstraints() {

        titleLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 10).isActive = true
        subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
        numberLabel.topAnchor.constraint(equalTo: subTitleLabel.bottomAnchor, constant: 10).isActive = true
        descLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 10).isActive = true
        
        titleLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        subTitleLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        numberLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        descLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        
        titleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        subTitleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        numberLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        descLabel.heightAnchor.constraint(equalToConstant: 80).isActive = true
    }
    
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        guard let textFieldText = textField.text, textFieldText.count == 8 else {
            self.infoLabel.text = "請輸入八個數字"
            self.numberLabel.text = ""
            self.descLabel.text = ""
            
            return
        }
        
        var userInput = Int(textFieldText)
        var isNotBingo = true
        let firtPrizeNumbers = awards.filter { $0.title == "頭獎"}.first!.numbers
        
        for ix in 0...2 {
            
            for number in awards[ix].numbers {
                
                //號碼全對，特別獎，特獎，頭獎
                if userInput == number {
                    
                    DispatchQueue.main.async {
                        self.subTitleLabel.text = self.awards[ix].title
                        self.numberLabel.text = "\(number!)"
                        self.descLabel.text = self.awards[ix].description
                        self.textField.textColor = .systemGreen
                    }
                    isNotBingo.toggle()
                }
            }
        }
        
        //查看是否中 二獎，三獎，肆獎，五獎，六獎
        if isNotBingo {
            var numbersDic = [Int:Int]()
            
            for (index, number) in firtPrizeNumbers.enumerated() {
                var correctNumbers = 0
                var number = number
                
                while (userInput ?? 0) % 10 == (number ?? 0) % 10 {
                        
                    userInput! /= 10
                    number! /= 10
                    correctNumbers += 1
                
                }
                numbersDic[index] = correctNumbers
            }
            let biggestNumber = numbersDic.values.max()!
            let bingoIndex = numbersDic.first(where: { $0.value == biggestNumber})?.key
            guard let bingoIndex = bingoIndex else { return }

            //中獎
            if biggestNumber >= 3 {
                DispatchQueue.main.async {
                    self.subTitleLabel.text = self.awards[10 - biggestNumber].title
                    self.numberLabel.text = "\(String(describing: self.awards[10 - biggestNumber].numbers[bingoIndex]!))"
                    self.descLabel.text = self.awards[10 - biggestNumber].description
                    self.infoLabel.text = "恭喜中獎"
                }
            }
            //沒有中獎
            else {
                self.infoLabel.text = "沒中獎"
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
    }
}



