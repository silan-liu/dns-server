//
//  DNSQuestion.swift
//  DNSServer
//
//  Created by liusilan on 2021/7/4.
//

import Foundation

// 查询类型
enum QueryType: Int {
    case Unknown = -1
    case A = 1
}

// 查询结构
struct DNSQuestion {
    var name: String = ""
    var type: QueryType = QueryType.Unknown
}

extension DNSQuestion {
    mutating func read(buffer: inout BytePacketBuffer) {
        
        // name
        self.name = buffer.readDomainName()
        
        // type, 2 byte
        self.type = QueryType.init(rawValue: Int(buffer.readU16())) ?? QueryType.Unknown
        
        // class
        _ = buffer.readU16()
    }
    
    mutating func write(buffer: inout BytePacketBuffer) {
        // name
        buffer.writeDomain(domain: name)
        
        // type
        buffer.writeU16(value: UInt16(type.rawValue))
        
        // class，默认 1
        buffer.write(value: 1)
    }
}
