//
//  DNSRecord.swift
//  DNSServer
//
//  Created by liusilan on 2021/7/4.
//

import Foundation

// ip 地址
struct Ipv4Addr {
    var num: [UInt8]
}

enum DNSRecord {
    // (domain, qtype, data_len, ttl)
    case Unknown(String, UInt16, UInt16, UInt32)
    
    // (domain, ip, ttl)
    case A(String, Ipv4Addr, UInt32)
}

extension DNSRecord {
    func read(buffer: inout BytePacketBuffer) -> DNSRecord {
        // name
        let domainName = buffer.readDomainName()
        
        // qtype
        let type = buffer.readU16()
        let queryType = QueryType.init(rawValue: Int(type)) ?? QueryType.Unknown
        
        // class
        _ = buffer.readU16()
        
        // ttl
        let ttl = buffer.readU32()
        
        // data_len
        let dataLen = buffer.readU16()
        
        if case QueryType.A = queryType {
            let ip = buffer.readU32()
            
            let d1 = UInt8((ip >> 24) & 0xf)
            let d2 = UInt8((ip >> 16) & 0xf)
            let d3 = UInt8((ip >> 8) & 0xf)
            let d4 = UInt8(ip & 0xf)
            
            let ipAddress = Ipv4Addr(num: [d1, d2, d3, d4])

            return DNSRecord.A(domainName, ipAddress, ttl)
        }
        
        return DNSRecord.Unknown(domainName, type, dataLen, ttl)
    }
}
