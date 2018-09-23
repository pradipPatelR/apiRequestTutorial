
import UIKit

class ViewController: UIViewController {
    
    
    let imageView: MyImageView = {
        let iv = MyImageView(frame: .zero)
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    var dataTask : URLSessionDataTask!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        self.view.addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 150).isActive = true
        imageView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 20).isActive = true
        imageView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20).isActive = true
        
        let height = view.frame.width - 40
        
        imageView.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        
        imageView.drawLayerView()
        
        
        
        let urlString = "https://upload.wikimedia.org/wikipedia/commons/6/6e/World%27s_Largest_Buffalo_Monument_2009.jpg"
        
        guard let url = URL(string: urlString) else { return print("Fail") }
        
        dataTask = URLSession.shared.dataTask(with: url, completionHandler: { (netData, _, _) in
            DispatchQueue.main.async {
                if let getData = netData, let getImage = UIImage(data: getData) {
                    self.imageView.image = getImage
                }
            }
        })
    
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: handelDatatask)
        
        dataTask.resume()
    }
    
    
    @objc func handelDatatask(tm:Timer) {
        
        print("countOfBytesExpectedToReceive: ", dataTask.countOfBytesExpectedToReceive)
        print("countOfBytesReceived: ", dataTask.countOfBytesReceived)
        
        let expectedReceived = dataTask.countOfBytesReceived
        let received = dataTask.countOfBytesReceived
        
        if received > 0 {
            let percentage = expectedReceived / received
            print("percentage: ", percentage )
            
            if expectedReceived == received {
                tm.invalidate()
                tm.fire()
            }
        }
        
        
    }
    
    
    
    
}



class MyImageView: UIImageView {
    
    private let openView:UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public var trackPoint: CGFloat = 0 {
        didSet(newValue){
            shapeLayer.strokeEnd = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(openView)
        openView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        openView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        openView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true
        openView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var shapeLayer: CAShapeLayer = CAShapeLayer()
    
    public func drawLayerView() {
        
        self.layoutIfNeeded()
        openView.layoutIfNeeded()
        
        
        let setCenter = openView.center
        
        let trackLayer = CAShapeLayer()
        
        let circularPath = UIBezierPath(arcCenter: setCenter, radius: 100, startAngle: (-CGFloat.pi / 2), endAngle: (2 * CGFloat.pi), clockwise: true)
        
        trackLayer.path = circularPath.cgPath
        
        trackLayer.strokeColor = UIColor.lightGray.cgColor
        trackLayer.lineWidth = 10
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = kCALineCapRound
        openView.layer.addSublayer(trackLayer)
        
        shapeLayer.path = circularPath.cgPath
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.lineWidth = 10
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = kCALineCapRound
        
        shapeLayer.strokeEnd = 0
        
        openView.layer.addSublayer(shapeLayer)
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handelTap)))
        
    }
    
    @objc private func handelTap() {
        
        trackPoint = 0
        
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        
        basicAnimation.toValue = 1
        basicAnimation.duration = 2
        basicAnimation.fillMode = kCAFillModeForwards
        basicAnimation.isRemovedOnCompletion = false
        
        shapeLayer.add(basicAnimation, forKey: "urSoBasic")
    }
    
    
}




class BaseClass : NSObject {
    
    override init() {
        super.init()
    }
    
    init(fromDictionary dictionary:[String:Any]) {
        
    }
    
    required init(coder Decoder:NSCoder) {
        
    }
}


class MyResponseClass : BaseClass {
    
    override init() {
        super.init()
    }
    
    override init(fromDictionary dictionary: [String : Any]) {
        super.init(fromDictionary: dictionary)
    }
    
    required init(coder Decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}












