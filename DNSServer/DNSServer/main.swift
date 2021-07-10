//
//  main.swift
//  DNSServer
//
//  Created by liusilan on 2021/7/4.
//

import Foundation
//import SwiftSocket

let path = "response_packet.txt"

let url = URL(fileURLWithPath: path)

do {
    let data = try Data(contentsOf: url)

    let bytes: [UInt8] = Array(data)

    var bytebuffer = BytePacketBuffer(buffer: bytes)
    
    let packet = DNSPacket.fromBuffer(buffer: &bytebuffer)
    
    print("\(packet)")
} catch  {
    print("read file error \(error)")
}

//

let domain = "google.com"
let queryType = QueryType.A

let udpController = UDPController()
udpController.initSocket()

// 发送的包
var packet = DNSPacket()

packet.header.id = 6666
packet.header.questionCount = 1
packet.header.recursionDesired = 1

let question = DNSQuestion(name: domain, type: queryType)

packet.questions.append(question)

var reqBuffer = BytePacketBuffer()
packet.write(buffer: &reqBuffer)

var res_buffer1 = BytePacketBuffer(buffer: reqBuffer.getCurrentRange())

let resPacket1 = DNSPacket.fromBuffer(buffer: &res_buffer1)
print(resPacket1)

udpController.sendBytes(bytes: reqBuffer.getCurrentRange())








