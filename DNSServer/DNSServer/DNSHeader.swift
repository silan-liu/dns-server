//
//  DNSHeader.swift
//  DNSServer
//
//  Created by liusilan on 2021/7/4.
//

import Foundation

enum ResultCode: Int {
    case NoError = 0
    case FormError
    case ServFail
    case NXDomain
    case NoTimp
    case Refused
}

struct DNSHeader {
    // id, 16 bits
    var id: UInt16 = 0
    
    // 请求/响应，1 bit，response = 1，为响应
    var response: Bool = false
    
    // 4 bits
    var opcode: UInt8 = 0
    
    // 1 bit
    var authoritativeAnswer: Bool = false
    
    // 1 bit，是否分片
    var trancated: Bool = false
    
    // 1 bit，是否期望递归查找，请求方使用
    var recursionDesired: Bool = false
    
    // 1 bit，服务器支持递归查找
    var recursionAvailable: Bool = false
    
    // 3 bits，保留字段
    var z: Bool = false
    
    // 4 bits，返回码
    var resCode: ResultCode = ResultCode.NoError
    
    // 16 bits，查询数目
    var questionCount: UInt16 = 0
    
    // 16 bits，结果数目
    var answerCount: UInt16 = 0
    
    // 16 bits，ns 数目
    var nsCount: UInt16 = 0
    
    // 16 bits，ar 附加数目
    var additionCount: UInt16 = 0
}

extension DNSHeader {
    // 从整个包中解析 dns header
    mutating func read(buffer: inout BytePacketBuffer) {
        // id，16 bits
        self.id = buffer.readU16()
        
        // 各种标志位，16 bits
        let flags = buffer.readU16()
        
        // 高 8 位
        let a = UInt8(flags >> 8)
        
        // qr
        self.response = (a & (1 << 7)) > 0
        
        // opcode
        self.opcode = (a >> 3 ) & 0xf
        
        // aa
        self.authoritativeAnswer = ((a >> 2) & 0x1) > 0
        
        // tc
        self.trancated = ((a >> 1) & 0x1) > 0

        // rd
        self.recursionDesired = (a & 0x1) > 0

        // 低 8 位
        let b = UInt8(flags & 0xff)
        
        // ra
        self.recursionAvailable = (b & (1 << 7)) > 0

        // z
        self.z = ((b >> 4) & 0x7) > 0

        // rescode
        self.response = (b & 0xf) > 0
        
        // count
        self.questionCount = buffer.readU16()
        self.answerCount = buffer.readU16()
        self.nsCount = buffer.readU16()
        self.additionCount = buffer.readU16()
    }
}
