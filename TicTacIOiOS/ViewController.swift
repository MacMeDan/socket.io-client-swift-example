//
//  ViewController.swift
//  TicTacIOiOS
//
//  Created by Erik Little on 3/7/15.
//

import UIKit

class ViewController: UIViewController, UIAlertViewDelegate {
    @IBOutlet weak var btn0:UIButton!
    @IBOutlet weak var btn1:UIButton!
    @IBOutlet weak var btn2:UIButton!
    @IBOutlet weak var btn3:UIButton!
    @IBOutlet weak var btn4:UIButton!
    @IBOutlet weak var btn5:UIButton!
    @IBOutlet weak var btn6:UIButton!
    @IBOutlet weak var btn7:UIButton!
    @IBOutlet weak var btn8:UIButton!
    @IBOutlet weak var label:UILabel!
    let socket = SocketIOClient(socketURL: NSURL(string:"http://localhost:8900")!)
    var name: String?
    var resetAck: SocketAckEmitter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addHandlers()
        socket.connect()
        
        let grad = CAGradientLayer()
        grad.frame = self.view.bounds
        
        let colors = [UIColor(red: 127, green: 0, blue: 127, alpha: 1).CGColor,
            UIColor(red: 0, green: 0, blue: 0, alpha: 1).CGColor]
        
        grad.colors = colors
        view.layer.insertSublayer(grad, atIndex: 0)
    }
    
    func addHandlers() {
        socket.on("startGame") {[weak self] data, ack in
            self?.handleStart()
            return
        }
        
        socket.on("name") {[weak self] data, ack in
            if let name = data[0] as? String {
                self?.name = name
            }
        }
        
        socket.on("playerMove") {[weak self] data, ack in
            if let name = data[0] as? String, x = data[1] as? Int, y = data[2] as? Int {
                self?.handlePlayerMove(name, coord: (x, y))
            }
        }
        
        socket.on("win") {[weak self] data, ack in
            if let name = data[0] as? String, typeDict = data[1] as? NSDictionary {
                self?.handleWin(name, type: typeDict)
            }
        }
        
        socket.on("draw") {[weak self] data, ack in
            self?.handleDraw()
            return
        }
        
        socket.on("currentTurn") {[weak self] data, ack in
            if let name = data[0] as? String {
                self?.handleCurrentTurn(name)
                
            }
        }
        
        socket.on("gameReset") {[weak self] data, ack in
            let alert = UIAlertView(title: "Play Again?",
                message: "Do you want to play another round?", delegate: self,
                cancelButtonTitle: "No", otherButtonTitles: "Yes")
            self?.resetAck = ack
            alert.show()
        }
        
        socket.on("gameOver") {data, ack in
            exit(0)
        }
        
        socket.onAny {print("Got event: \($0.event), with items: \($0.items)")}
    }
    
    @IBAction func btnClicked(btn: UIButton) {
        let coord:(x: Int, y: Int)
        
        switch btn.tag {
        case 0:
            coord = (0, 0)
        case 1:
            coord = (0, 1)
        case 2:
            coord = (0, 2)
        case 3:
            coord = (1, 0)
        case 4:
            coord = (1, 1)
        case 5:
            coord = (1, 2)
        case 6:
            coord = (2, 0)
        case 7:
            coord = (2, 1)
        case 8:
            coord = (2, 2)
        default:
            coord = (-1, -1)
        }
        
        socket.emit("playerMove", coord.x, coord.y)
    }
    
    func drawWinLine(type: NSDictionary) {
        let winType = type["type"] as! String
        let to: CGPoint
        let from: CGPoint
        
        if winType == "row" {
            let row = type["num"] as! Int
            
            switch row {
            case 0:
                to = btn2.center
                from = btn0.center
            case 1:
                to = btn3.center
                from = btn5.center
            case 2:
                to = btn6.center
                from = btn8.center
            default:
                to = CGPointMake(0.0, 0.0)
                from = CGPointMake(0.0, 0.0)
            }
        } else if winType == "col" {
            let row = type["num"] as! Int
            
            switch row {
            case 0:
                to = btn6.center
                from = btn0.center
            case 1:
                to = btn7.center
                from = btn1.center
            case 2:
                to = btn2.center
                from = btn8.center
            default:
                to = CGPointMake(0.0, 0.0)
                from = CGPointMake(0.0, 0.0)
            }
        } else {
            let coord = type["coord"] as! NSDictionary
            let x = coord["x"] as! Int
            let y = coord["y"] as! Int
            
            switch (x, y) {
            case (0, 0):
                to = btn8.center
                from = btn0.center
            case (0, 2):
                to = btn6.center
                from = btn2.center
            case (2, 2):
                to = btn0.center
                from = btn8.center
            case (2, 0):
                to = btn2.center
                from = btn6.center
            default:
                to = CGPointMake(0.0, 0.0)
                from = CGPointMake(0.0, 0.0)
            }
        }
        
        let path = UIBezierPath()
        path.moveToPoint(from)
        path.addLineToPoint(to)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.CGPath
        shapeLayer.strokeColor = UIColor.whiteColor().CGColor
        shapeLayer.lineWidth = 3.0
        shapeLayer.fillColor = UIColor.clearColor().CGColor
        view.layer.addSublayer(shapeLayer)
    }
    
    func handleCurrentTurn(name: String) {
        if name == self.name! {
            label.text = "Your turn!"
        } else {
            label.text = "Opponents turn!"
        }
    }
    
    func handleDraw() {
        label.text = "Draw!"
    }
    
    func handleGameReset() {
        btn0.setTitle("-", forState: UIControlState.Normal)
        btn1.setTitle("-", forState: UIControlState.Normal)
        btn2.setTitle("-", forState: UIControlState.Normal)
        btn3.setTitle("-", forState: UIControlState.Normal)
        btn4.setTitle("-", forState: UIControlState.Normal)
        btn5.setTitle("-", forState: UIControlState.Normal)
        btn6.setTitle("-", forState: UIControlState.Normal)
        btn7.setTitle("-", forState: UIControlState.Normal)
        btn8.setTitle("-", forState: UIControlState.Normal)
        
        btn0.enabled = true
        btn1.enabled = true
        btn2.enabled = true
        btn3.enabled = true
        btn4.enabled = true
        btn5.enabled = true
        btn6.enabled = true
        btn7.enabled = true
        btn8.enabled = true
        
        view.layer.sublayers?.removeLast()
        label.text = "Waiting for Opponent"
    }
    
    func handlePlayerMove(name: String, coord: (Int, Int)) {
        switch coord {
        case (0, 0):
            btn0.setTitle(name, forState: UIControlState.Disabled)
            btn0.enabled = false
        case (0, 1):
            btn1.setTitle(name, forState: UIControlState.Disabled)
            btn1.enabled = false
        case (0, 2):
            btn2.setTitle(name, forState: UIControlState.Disabled)
            btn2.enabled = false
        case (1, 0):
            btn3.setTitle(name, forState: UIControlState.Disabled)
            btn3.enabled = false
        case (1, 1):
            btn4.setTitle(name, forState: UIControlState.Disabled)
            btn4.enabled = false
        case (1, 2):
            btn5.setTitle(name, forState: UIControlState.Disabled)
            btn5.enabled = false
        case (2, 0):
            btn6.setTitle(name, forState: UIControlState.Disabled)
            btn6.enabled = false
        case (2, 1):
            btn7.setTitle(name, forState: UIControlState.Disabled)
            btn7.enabled = false
        case (2, 2):
            btn8.setTitle(name, forState: UIControlState.Disabled)
            btn8.enabled = false
        default:
            return
        }
    }
    
    func handleStart() {
        if name == "X" {
            label.text = "Your turn!"
        } else {
            label.text = "Opponents turn"
        }
    }
    
    func handleWin(name: String, type: NSDictionary) {
        label.text = "Player \(name) won!"
        drawWinLine(type)
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            resetAck?.with(false)
        } else {
            handleGameReset()
            resetAck?.with(true)
        }
    }
}

