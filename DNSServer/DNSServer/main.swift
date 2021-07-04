//
//  main.swift
//  DNSServer
//
//  Created by liusilan on 2021/7/4.
//

import Foundation

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


