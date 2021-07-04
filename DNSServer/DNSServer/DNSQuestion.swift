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


struct DNSQuestion {
    var name: String
    var type: QueryType
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
}
