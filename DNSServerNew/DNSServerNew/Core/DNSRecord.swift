//
//  DNSRecord.swift
//  DNSServer
//
//  Created by liusilan on 2021/7/4.
//

import Foundation

// ip 地址
struct Ipv4Addr: CustomDebugStringConvertible {
    var nums: [UInt8]
    
    var debugDescription: String {
        var desc = ""
        for i in 0..<nums.count {
            desc += "\(nums[i])"
            
            if i < nums.count - 1 {
                desc += "."
            }
        }
        
        return desc
    }
}

// ip 地址
struct Ipv6Addr: CustomDebugStringConvertible {
    var nums: [UInt16]
    
    var debugDescription: String {
        var desc = ""
        for i in 0..<nums.count {
            desc += "\(nums[i])"
            
            if i < nums.count - 1 {
                desc += "."
            }
        }
        
        return desc
    }
}

// 返回的记录结构
enum DNSRecord {
    // (domain, qtype, data_len, ttl)
    case Unknown(String, UInt16, UInt16, UInt32)
    
    // (domain, ip, ttl)
    case A(String, Ipv4Addr, UInt32)
    
    // (domain, host, ttl)
    case NS(String, String, UInt32)
    
    // (domain, host, ttl)
    case CNAME(String, String, UInt32)
    
    // (domain, priority, host, ttl)
    case MX(String, UInt16, String, UInt32)
    
    // (domain, ip, ttl)
    case AAAA(String, Ipv6Addr, UInt32)
}

extension DNSRecord {
    static func read(buffer: inout BytePacketBuffer) -> DNSRecord {
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
        
        switch queryType {
        case .A:
            // ip 地址，4 字节
            let ip = buffer.readU32()
            
            let d1 = UInt8((ip >> 24) & 0xff)
            let d2 = UInt8((ip >> 16) & 0xff)
            let d3 = UInt8((ip >> 8) & 0xff)
            let d4 = UInt8(ip & 0xff)
                        
            let ipAddress = Ipv4Addr(nums: [d1, d2, d3, d4])

            return DNSRecord.A(domainName, ipAddress, ttl)
            
        case .AAAA:
            var addressList: [UInt16] = []
            
            // 读取 16 字节
            for _ in 0...3 {
                let addr = buffer.readU32()

                // 高 16 位
                let h16 = UInt16((addr >> 16) & 0xffff)
                
                // 低 16 位
                let l16 = UInt16(addr & 0xffff)
                
                addressList.append(h16)
                addressList.append(l16)
            }
            
            let ipv6 = Ipv6Addr(nums: addressList)
            
            return DNSRecord.AAAA(domainName, ipv6, ttl)
            
        case .NS:
            let ns = buffer.readDomainName()
            return DNSRecord.NS(domainName, ns, ttl)
            
        case .CNAME:
            
            let cname = buffer.readDomainName()
            return DNSRecord.CNAME(domainName, cname, ttl)
            
        case .MX:
            let priority = buffer.readU16()
            let mx = buffer.readDomainName()
            
            return DNSRecord.MX(domainName, priority, mx, ttl)
            
        default:
            return DNSRecord.Unknown(domainName, type, dataLen, ttl)
        }
    }
    
    func write(buffer: inout BytePacketBuffer) {
        switch self {
        case let .A(domain, ip, ttl):
            // domain
            buffer.writeDomain(domain: domain)
            
            // qtype
            buffer.writeU16(value: UInt16(QueryType.A.rawValue))
            
            // class
            buffer.writeU16(value: 1)
            
            // ttl
            buffer.writeU32(value: ttl)
            
            // data_len
            buffer.writeU16(value: 4)
            
            // ip
            for num in ip.nums {
                
                buffer.writeU8(value: num)
            }
            
        case let .AAAA(domain, ip, ttl):
            // domain
            buffer.writeDomain(domain: domain)
            
            // qtype
            buffer.writeU16(value: UInt16(QueryType.AAAA.rawValue))
            
            // class
            buffer.writeU16(value: 1)

            // ttl
            buffer.writeU32(value: ttl)
            
            // data_len
            buffer.writeU16(value: 16)
            
            for num in ip.nums {
                buffer.writeU16(value: num)
            }
            
        case let .NS(domain, host, ttl):
            // domain
            buffer.writeDomain(domain: domain)
            
            // qtype
            buffer.writeU16(value: UInt16(QueryType.NS.rawValue))
            
            // class
            buffer.writeU16(value: 1)

            // ttl
            buffer.writeU32(value: ttl)
            
            let pos = buffer.pos
            
            // 数据长度占位
            buffer.writeU16(value: 0)
            
            buffer.writeDomain(domain: host)
            
            // 计算 host 的长度并写入
            let size = buffer.pos - (pos + 2)
            buffer.setU16(pos: pos, value: UInt16(size))
            
        case let .CNAME(domain, host, ttl):
            // domain
            buffer.writeDomain(domain: domain)
            
            // qtype
            buffer.writeU16(value: UInt16(QueryType.CNAME.rawValue))
            
            // class
            buffer.writeU16(value: 1)

            // ttl
            buffer.writeU32(value: ttl)
            
            let pos = buffer.pos
            
            // 数据长度占位
            buffer.writeU16(value: 0)
            buffer.writeDomain(domain: host)
            
            // 计算 host 的长度并写入
            let size = buffer.pos - (pos + 2)
            buffer.setU16(pos: pos, value: UInt16(size))
        
        case let .MX(domain, priority, host, ttl):
            buffer.writeDomain(domain: domain)
            
            // qtype
            buffer.writeU16(value: UInt16(QueryType.MX.rawValue))
            
            // class
            buffer.writeU16(value: 1)

            // ttl
            buffer.writeU32(value: ttl)
            
            let pos = buffer.pos
            
            // 数据长度占位
            buffer.writeU16(value: 0)
            buffer.writeU16(value: priority)
            buffer.writeDomain(domain: host)
            
            // 计算 host 的长度并写入
            let size = buffer.pos - (pos + 2)
            buffer.setU16(pos: pos, value: UInt16(size))
            
        default:
            print("it is not a valid record, skipping...")
            break
        }
    }
}
