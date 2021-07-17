//
//  ViewController.swift
//  DNSServerNew
//
//  Created by liusilan on 2021/7/10.
//

import Cocoa
import CocoaAsyncSocket

class ViewController: NSViewController, GCDAsyncUdpSocketDelegate {

    lazy var udpSocket: GCDAsyncUdpSocket = {
        let socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try socket.bind(toPort: 9875)
            try socket.beginReceiving()
            
        } catch {
            print("error;\(error)")
        }
        
        return socket
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    /// 读取本地响应包数据
    @IBAction func readLocalRsp(sender: NSButton) {
        if let path = Bundle.main.path(forResource: "response_packet", ofType: "txt") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))

                let bytes: [UInt8] = Array(data)

                var bytebuffer = BytePacketBuffer(buffer: bytes)
                
                let packet = DNSPacket.fromBuffer(buffer: &bytebuffer)
                
                print("\(packet)")
            } catch  {
                print("read file error \(error)")
            }
        }
    }
    
    /// 向服务器查询 google.com 的 ip 地址
    @IBAction func query(sender: NSButton) {

        let domain = "yahoo.com"

//        let domain = "google.com"
        let queryType = QueryType.A

        // 发送的包
        var packet = DNSPacket()

        packet.header.id = 6666
        packet.header.questionCount = 1
        packet.header.recursionDesired = 1

        let question = DNSQuestion(name: domain, type: queryType)

        packet.questions.append(question)

        var reqBuffer = BytePacketBuffer()
        packet.write(buffer: &reqBuffer)
        
        sendBytes(bytes: reqBuffer.getCurrentRange())
    }

    
    /// 发送 udp 数据
    /// - Parameter bytes: 字节
    func sendBytes(bytes: [UInt8]) {
        let data = Data(bytes)
        udpSocket.send(data, toHost: "8.8.8.8", port: 53, withTimeout: 10, tag: 1)
    }

    //MARK: - GCDAsyncUdpSocketDelegate
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("send data")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        
        let bytes: [UInt8] = Array(data)

        var bytebuffer = BytePacketBuffer(buffer: bytes)
        
        let packet = DNSPacket.fromBuffer(buffer: &bytebuffer)
        
        print("receive packet\(packet)")
    }
}

