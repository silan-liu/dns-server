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
}
