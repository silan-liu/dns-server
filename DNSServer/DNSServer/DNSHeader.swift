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
    var response: UInt8 = 0
    
    // 4 bits
    var opcode: UInt8 = 0
    
    // 1 bit
    var authoritativeAnswer: UInt8 = 0
    
    // 1 bit，是否分片
    var trancated: UInt8 = 0
    
    // 1 bit，是否期望递归查找，请求方使用
    var recursionDesired: UInt8 = 0
    
    // 1 bit，服务器支持递归查找
    var recursionAvailable: UInt8 = 0
    
    // 3 bits，保留字段
    var z: UInt8 = 0
    
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
        self.response = a & (1 << 7)
        
        // opcode
        self.opcode = UInt8((a >> 3) & 0xf)
        
        // aa
        self.authoritativeAnswer = (a >> 2) & 0x1
        
        // tc
        self.trancated = (a >> 1) & 0x1

        // rd
        self.recursionDesired = a & 0x1

        // 低 8 位
        let b = UInt8(flags & 0xff)
        
        // ra
        self.recursionAvailable = b & (1 << 7)

        // z
        self.z = (b >> 4) & 0x7

        // rescode
        self.resCode = ResultCode.init(rawValue: Int((b & 0xf))) ?? ResultCode.NoError
        
        // count
        self.questionCount = buffer.readU16()
        self.answerCount = buffer.readU16()
        self.nsCount = buffer.readU16()
        self.additionCount = buffer.readU16()
    }
    
    
    /// 将 header 写入包中
    /// - Parameter buffer: 包数据
    mutating func write(buffer: inout BytePacketBuffer) {
        // id
        buffer.writeU16(value: self.id)
        
        // 高 8 位标志，QR-1、OPCODE-4、AA-1、TC-1、RD-1
        let qr: UInt8 = response << 7
        let opCode: UInt8 = ((opcode & 0xf) << 3)
        let aa: UInt8 = authoritativeAnswer << 2
        let tc: UInt8 = trancated << 1
        let rd: UInt8 = recursionDesired
        
        let h8 = UInt8(qr | opCode | aa | tc | rd)
        buffer.write(value: h8)
        
        // 低 8 位标志，RA-1、Z-3、RCODE-4
        let ra: UInt8 = recursionAvailable << 7
        let flagZ: UInt8 = (z & 0x7) << 4
        let rcode = UInt8(resCode.rawValue & 0xf)
        
        let l8 = ra | flagZ | rcode
        buffer.write(value: l8)
        
        // count
        buffer.writeU16(value: questionCount)
        buffer.writeU16(value: answerCount)
        buffer.writeU16(value: nsCount)
        buffer.writeU16(value: additionCount)
    }
}
