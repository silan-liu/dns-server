//
//  DNSPacket.swift
//  DNSServer
//
//  Created by liusilan on 2021/7/4.
//

import Foundation

// dns 包结构
struct DNSPacket {
    var header: DNSHeader = DNSHeader()
    var questions: [DNSQuestion] = []
    var answers: [DNSRecord] = []
    var authorities: [DNSRecord] = []
    var resources: [DNSRecord] = []
}

extension DNSPacket {
    static func fromBuffer(buffer: inout BytePacketBuffer) -> DNSPacket {
        var packet = DNSPacket()
        
        // header
        packet.header.read(buffer: &buffer)
                
        // questions
        for _ in 0..<packet.header.questionCount {
            var question = DNSQuestion()
            
            question.read(buffer: &buffer)
            
            packet.questions.append(question)
        }
        
        // answers
        for _ in 0..<packet.header.answerCount {
            let record = DNSRecord.read(buffer: &buffer)
            
            packet.answers.append(record)
        }
        
        // name server
        for _ in 0..<packet.header.nsCount {
            let record = DNSRecord.read(buffer: &buffer)
            
            packet.authorities.append(record)
        }
        
        // addition
        for _ in 0..<packet.header.additionCount {
            let record = DNSRecord.read(buffer: &buffer)
            
            packet.resources.append(record)
        }
        
        return packet
    }
    
    mutating func write(buffer: inout BytePacketBuffer) {
        // header count 赋值
        header.questionCount = UInt16(questions.count)
        header.answerCount = UInt16(answers.count)
        header.nsCount = UInt16(authorities.count)
        header.additionCount = UInt16(resources.count)
        
        // 写入
        header.write(buffer: &buffer)
                
        // questions
        for var question in questions {
            question.write(buffer: &buffer)
        }
        
        // answers
        for answer in answers {
            answer.write(buffer: &buffer)
        }
        
        // authority
        for authority in authorities {
            authority.write(buffer: &buffer)
        }
        
        // resource
        for resource in resources {
            resource.write(buffer: &buffer)
        }
    }
    
    // 从返回的数据中，选择一个随机的 ip
    func getRandomIP() -> Ipv4Addr? {
        
        let ipList = self.answers.compactMap { record -> Ipv4Addr? in
            if case let DNSRecord.A(_, ip, _) = record {
                return ip
            }
            
            return nil
        }
        
        let random = Int.random(in: 0..<ipList.count)

        return ipList[random]
    }
    
    // 返回域名对应的 NS 列表，类型元组，(domain, host)
    // google.com.        172800    IN    NS    ns2.google.com.
    func getNS(qname: String) -> Array<(String, String)>? {
        let nsList = self.authorities.compactMap { record -> (String, String)? in
            if case let DNSRecord.NS(domain, host, _) = record {
                
                // 如果要查询的域名以 ns 域名结尾，表明在该 ns 服务器的分管之下
                if qname.hasSuffix(domain) {
                    return (domain, host)
                }
            }
            
            return nil
        }
        
       return nsList
    }
    
    // 从 additon resource 中获取 ns 的 ip
    // ns2.google.com.        172800    IN    A    216.239.34.10
    func getResolvedNS(qname: String) -> Ipv4Addr? {
     
        if let nsList = getNS(qname: qname) {
            // 每个 ns 去 resource 中查找 ip
            for (_, host) in nsList {
                let resultList = self.resources.compactMap { record -> Ipv4Addr? in
                    if case let DNSRecord.A(domain, ip, _) = record {
                        if host == domain {
                            return ip
                        }
                    }
                    
                    return nil
                }
                
                if resultList.count > 0 {
                    return resultList.first
                }
            }
        }
        
        
        return nil
    }
    
    // 如果 additon resource 没有 ns 的 ip，那么返回 ns 的 host，之后重新进行域名解析查询 ns 的 ip。
    func getUnresolvedNS(qname: String) -> String? {
        return getNS(qname: qname)?.first?.1
    }
}
