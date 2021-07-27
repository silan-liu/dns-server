//
//  DNSServer.swift
//  DNSServerNew
//
//  Created by liusilan on 2021/7/27.
//

import Foundation
import CocoaAsyncSocket

class DNSServer: NSObject, GCDAsyncUdpSocketDelegate {
    
    var completion: ((DNSPacket) -> ())?
    
    // client socket
    lazy var clientSocket: GCDAsyncUdpSocket = {
        let socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try socket.bind(toPort: 4321)
            try socket.beginReceiving()
            
        } catch {
            print("error;\(error)")
        }
        
        return socket
    }()
    
    // server socket
    lazy var serverSocket: GCDAsyncUdpSocket = {
        let socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try socket.bind(toPort: 3004)
            
        } catch {
            print("error;\(error)")
        }
        
        return socket
    }()
    
    // 启动服务
    func start() {
        do {
            try serverSocket.beginReceiving()
            
            print("start dns server...")
        } catch {
            print("error;\(error)")
        }
    }
    
    /// 查询域名对应的 ip 地址，向 8.8.8.8 公共 DNS 服务器查询
    /// - Parameters:
    ///   - domain: 域名
    ///   - queryType: 类型
    ///   - completion: 查询回调
    /// - Returns:
    func lookup(domain: String, queryType: QueryType, completion: @escaping (DNSPacket) -> ()) {
        
        self.completion = completion
        
        // 向 8.8.8.8 查询
        var packet = DNSPacket()
        
        packet.header.id = 6666
        packet.header.questionCount = 1
        packet.header.recursionDesired = 1
        
        let question = DNSQuestion(name: domain, type: queryType)

        packet.questions.append(question)

        var reqBuffer = BytePacketBuffer()
        packet.write(buffer: &reqBuffer)
        
        // 发送数据
        let data = Data(reqBuffer.getCurrentRange())
        clientSocket.send(data, toHost: "8.8.8.8", port: 53, withTimeout: 30, tag: 1)
    }
    
    func handleQuery(request: DNSPacket, address: Data) {
        // 构造响应 packet
        var packet = DNSPacket()
        
        packet.header.id = request.header.id
        packet.header.recursionDesired = 1
        packet.header.recursionAvailable = 1
        packet.header.response = 1
        
        if let question = request.questions.first {
            print("received query:\(question)")
            
            // 查询
            lookup(domain: question.name, queryType: question.type) { resultPacket in
                
                print("lookup result:\(resultPacket)")
                
                // 将查询到的数据填充到响应包中
                packet.questions.append(question)
                packet.header.questionCount = 1
                
                packet.header.resCode = request.header.resCode

                packet.answers.append(contentsOf: resultPacket.answers)
                packet.header.answerCount = UInt16(resultPacket.answers.count)

                packet.authorities.append(contentsOf: resultPacket.authorities)
                packet.header.nsCount = UInt16(resultPacket.authorities.count)

                packet.resources.append(contentsOf: resultPacket.resources)
                packet.header.additionCount = UInt16(resultPacket.resources.count)
                
                // 发送回包
                self.sendRspPacket(packet: &packet, address: address)
            }
        } else {
            packet.header.resCode = ResultCode.FormError
            
            // 发送回包
            self.sendRspPacket(packet: &packet, address: address)
        }
    }
    
    // 发送回包给客户端
    func sendRspPacket(packet: inout DNSPacket, address: Data) {
        
        // 转成二进制
        var rspBuffer = BytePacketBuffer()
        packet.write(buffer: &rspBuffer)
        
        let data = Data(rspBuffer.getCurrentRange())
                        
        // 返回数据给客户端
        self.serverSocket.send(data, toAddress: address, withTimeout: 30, tag: 2)
    }
    
    
    /// 将二进制数据转换成 dns 包
    /// - Parameter data: 二进制数据
    /// - Returns: dns 包
    func packetFromData(data: Data) -> DNSPacket {
        let bytes: [UInt8] = Array(data)

        var bytebuffer = BytePacketBuffer(buffer: bytes)
        
        let packet = DNSPacket.fromBuffer(buffer: &bytebuffer)
        
        return packet
    }

    //MARK: - GCDAsyncUdpSocketDelegate
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("send data")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        
        let packet = packetFromData(data: data)
        
        if sock == serverSocket {
        
            print("receive query packet:\(packet)")
            
            // 处理查询包
            handleQuery(request: packet, address: address)
            
        } else if sock == clientSocket {
            print("receive response packet:\(packet)")
            
            // 查询结果
            self.completion?(packet)
        }
    }
}
