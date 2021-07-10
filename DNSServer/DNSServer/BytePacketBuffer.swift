//
//  BytePacketBuffer.swift
//  DNSServer
//
//  Created by liusilan on 2021/7/4.
//

import Foundation

let MaxBufferSize = 512

// buffer
struct BytePacketBuffer {
    var buffer: Array<UInt8>
    var pos: Int = 0
}

extension BytePacketBuffer {
    init() {
        buffer = Array(repeating: 0, count: MaxBufferSize)
        pos = 0
    }

    //MARK: - read
    
    mutating func step(step: Int) {
        pos += step
    }
    
    mutating func seek(pos: Int) {
        self.pos = pos
    }
    
    // 读取一个字节，指针后移
    mutating func read() -> UInt8 {
        if pos >= buffer.count {
            print("End of buffer")
            return 0
        }
        
        let res = buffer[pos]
        
        pos += 1
        
        return res
    }
    
    func get(pos: Int) -> UInt8 {
        if pos >= buffer.count {
            print("End of buffer")
            return 0
        }
        
        let res = buffer[pos]
        
        return res
    }
    
    
    /// 读取指定区间数据
    /// - Parameters:
    ///   - start: 开始位置
    ///   - len: 长度
    /// - Returns: 数据数组
    func getRange(start: Int, len: Int) -> [UInt8] {
        if start + len >= buffer.count {
            return []
        }
        
        let res = buffer[start..<start+len]
        return Array(res)
    }
    
    // 读取 4 个字节
    mutating func readU32() -> UInt32 {
        let b1 = UInt32(read())
        let b2 = UInt32(read())
        let b3 = UInt32(read())
        let b4 = UInt32(read())

        
        return ((b1 << 24) | (b2 << 16) | (b3 << 8) | (b4))
    }
    
    // 读取 2 个字节
    mutating func readU16() -> UInt16 {
        let b1 = UInt16(read())
        let b2 = UInt16(read())
        
        let result = ((b1 << 8) | b2)
        return result
    }
    
    
    /// 读取域名，域名以 . 分隔，但是 . 不会出现在数据中。
    ///
    /// 1. 一般情况下：分隔后的数据，每部分数据前面会带上数据长度（1 字节），也就是 {长度+数据} 的格式，最后末尾是 0x00 空字符，表示结束。
    /// 比如 google.com，数据表示为： 6+google+3+com 的形式，末尾再加上 0x00。
    ///
    /// 2. 但有一种特殊情况：当长度数据以 0x11 开头时，此时表示它之后的一个字节也是数据长度，也就是说 2 个字节为数据长度，但需去除高 2 位 0x11，余下的数据表示偏移，然后跳转到该偏移，再读取真正的域名数据。
    /// 比如，0xc00c，c0 以 11 开头，那么 0xc00c 去除高两位的数据为 0xc00c ^ 0xc000 = 0x0c，表示从整个数据包偏移 0x0c 的位置去获取域名数据。
    mutating func readDomainName() -> String {
        var curPos = pos
        
        // 情况 2 中是否已跳转到偏移位置
        var jumped = false
        
        // 最大跳转次数，防止有人伪造包数据，导致不断循环
        let maxJumps = 5
        
        // 已跳转次数
        var jumpedCount = 0
        
        // 分隔符，初始为空，之后变为 .
        var delimeter = ""
        
        var domain = ""
        
        while true {
            // 大于最大跳转数
            if jumpedCount > maxJumps {
                print("Limit of \(maxJumps) exceeded")
                return ""
            }
            
            // 读取数据长度
            let len = get(pos: curPos)
            
            //  情况 2
            if len & 0xC0 == 0xC0 {
                if !jumped {
                    // 更新内部位置
                    seek(pos: pos + 2)
                }
                
                // 取出后一字节
                let b2 = get(pos: curPos + 1)
                
                //  去除高 2 位，得到跳转偏移数据
                let offset = Int(((len ^ 0xc0) << 8) | b2)
                
                // 重新循环
                curPos = offset
                
                jumped = true
                jumpedCount += 1
                
                continue
            } else {
                
                // 跳过长度
                curPos += 1
                
                // 到了末尾
                if len == 0 {
                    break
                }
                
                domain += delimeter
                
                // 读取相应长度数据
                let data = getRange(start: curPos, len: Int(len))
                
                let name = String(bytes: data, encoding: .ascii) ?? ""
                                
                domain += name
                
                delimeter = "."
                
                // 跳过数据
                curPos += Int(len)
            }
        }
        
        // 更新位置
        if !jumped {
            seek(pos: curPos)
        }
        
        return domain
    }
    
    //MARK: - write

    /// 写入 8 位无符号整数
    /// - Parameter value: 8 位无符号整数
    mutating func write(value: UInt8) {
        if self.pos >= MaxBufferSize {
            print("Exceed max size of buffer")
            return
        }
        
        buffer[pos] = value
        pos += 1
    }
    
    /// 写入 8 位无符号整数
    /// - Parameter value: 8 位无符号整数
    mutating func writeU8(value: UInt8) {
        write(value: value)
    }
    
    /// 写入 16 位无符号整数
    /// - Parameter value: 16 位无符号整数
    mutating func writeU16(value: UInt16) {
        // 高 8 位
        let h8 = UInt8(value >> 8)
        write(value: h8)
        
        // 低 8 位
        let l8 = UInt8(value & 0xff)
        write(value: l8)
    }
    
    /// 写入 32 位无符号整数
    /// - Parameter value: 32 位无符号整数
    mutating func writeU32(value: UInt32) {
        // 最高 8 位
        write(value: UInt8(value >> 24))
        write(value: UInt8(value >> 16))
        write(value: UInt8(value >> 8))
        write(value: UInt8(value & 0xff))
    }
    
    
    /// 写入域名
    /// - Parameter domain: 域名
    mutating func writeDomain(domain: String) {
        let components = domain.split(separator: ".")
        for label in components {
            let len = label.count
            
            if len > 0x3f {
                print("label len exceeds 63 characters")
                continue
            }
            
            // 写入数据长度
            write(value: UInt8(len))
            
            // 写入数据
            for char in label {
                if let asciiValue = char.asciiValue {
                    write(value: UInt8(asciiValue))
                }
            }
        }
        
        // 写入结束符 0
        write(value: 0)
    }
}
