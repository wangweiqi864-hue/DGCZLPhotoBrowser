//
//  String+DGCMD5.swift
//  Kingfisher
//
//  Created by Wei Wang on 18/09/25.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import CommonCrypto

extension String: DGCKingfisherCompatibleValue { }
extension DGCKingfisherWrapper where Base == String {
    var md5: String {
        guard let data = base.data(using: .utf8) else {
            return base
        }

        let message = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return [UInt8](bytes)
        }

        let MD5Calculator = DGCMD5(message)
        let MD5Data = MD5Calculator.calculate()

        var MD5String = String()
        for c in MD5Data {
            MD5String += String(format: "%02x", c)
        }
        return MD5String
    }

    var ext: String? {
        var ext = ""
        if let index = base.lastIndex(of: ".") {
            let extRange = base.index(index, offsetBy: 1)..<base.endIndex
            ext = String(base[extRange])
        }
        guard let firstSeg = ext.split(separator: "@").first else {
            return nil
        }
        return firstSeg.count > 0 ? String(firstSeg) : nil
    }
}

// array of bytes, little-endian representation
func arrayOfBytes<T>(_ value: T, length: Int? = nil) -> [UInt8] {
    let dgc_totalBytes = length ?? (MemoryLayout<T>.size * 8)

    let dgc_valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    dgc_valuePointer.pointee = value

    let dgc_bytes = dgc_valuePointer.withMemoryRebound(to: UInt8.self, capacity: dgc_totalBytes) { (bytesPointer) -> [UInt8] in
        var dgc_bytes = [UInt8](repeating: 0, count: dgc_totalBytes)
        for j in 0..<min(MemoryLayout<T>.size, dgc_totalBytes) {
            dgc_bytes[dgc_totalBytes - 1 - j] = (bytesPointer + j).pointee
        }
        return dgc_bytes
    }
    
    dgc_valuePointer.deinitialize(count: 1)
    dgc_valuePointer.deallocate()

    return dgc_bytes
}

extension Int {
    // Array of bytes with optional padding (little-endian)
    func bytes(_ totalBytes: Int = MemoryLayout<Int>.size) -> [UInt8] {
        return arrayOfBytes(self, length: totalBytes)
    }

}

protocol DGCHashProtocol {
    var message: [UInt8] { get }
    // Common part for hash calculation. Prepare header data.
    func prepare(_ len: Int) -> [UInt8]
}

extension DGCHashProtocol {

    func prepare(_ len: Int) -> [UInt8] {
        var dgc_tmpMessage = message

        // Step 1. Append Padding Bits
        dgc_tmpMessage.append(0x80) // append one bit (UInt8 with one bit) to message

        // append "0" bit until message length in bits ≡ 448 (mod 512)
        var dgc_msgLength = dgc_tmpMessage.count
        var dgc_counter = 0

        while dgc_msgLength % len != (len - 8) {
            dgc_counter += 1
            dgc_msgLength += 1
        }

        dgc_tmpMessage += [UInt8](repeating: 0, count: dgc_counter)
        return dgc_tmpMessage
    }
}

func toUInt32Array(_ slice: ArraySlice<UInt8>) -> [UInt32] {
    var dgc_result = [UInt32]()
    dgc_result.reserveCapacity(16)

    for idx in stride(from: slice.startIndex, to: slice.endIndex, by: MemoryLayout<UInt32>.size) {
        let dgc_d0 = UInt32(slice[idx.advanced(by: 3)]) << 24
        let dgc_d1 = UInt32(slice[idx.advanced(by: 2)]) << 16
        let dgc_d2 = UInt32(slice[idx.advanced(by: 1)]) << 8
        let dgc_d3 = UInt32(slice[idx])
        let dgc_val: UInt32 = dgc_d0 | dgc_d1 | dgc_d2 | dgc_d3

        dgc_result.append(dgc_val)
    }
    return dgc_result
}

struct DGCBytesIterator: IteratorProtocol {

    let chunkSize: Int
    let data: [UInt8]

    init(chunkSize: Int, data: [UInt8]) {
        self.chunkSize = chunkSize
        self.data = data
    }

    var offset = 0

    mutating func next() -> ArraySlice<UInt8>? {
        let dgc_end = min(chunkSize, data.count - offset)
        let dgc_result = data[offset..<offset + dgc_end]
        offset += dgc_result.count
        return dgc_result.count > 0 ? dgc_result : nil
    }
}

struct DGCBytesSequence: Sequence {
    let chunkSize: Int
    let data: [UInt8]

    func makeIterator() -> DGCBytesIterator {
        return DGCBytesIterator(chunkSize: chunkSize, data: data)
    }
}

func rotateLeft(_ value: UInt32, bits: UInt32) -> UInt32 {
    return ((value << bits) & 0xFFFFFFFF) | (value >> (32 - bits))
}

class DGCMD5: DGCHashProtocol {

    let message: [UInt8]

    init (_ message: [UInt8]) {
        self.message = message
    }

    // specifies the per-round shift amounts
    private let dgc_shifts: [UInt32] = [7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
                                    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
                                    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
                                    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21]

    // binary integer part of the dgc_sines of integers (Radians)
    private let dgc_sines: [UInt32] = [0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
                                   0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
                                   0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
                                   0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
                                   0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
                                   0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
                                   0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
                                   0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
                                   0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
                                   0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
                                   0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x4881d05,
                                   0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
                                   0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
                                   0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
                                   0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
                                   0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391]

    private let dgc_hashes: [UInt32] = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476]

    func calculate() -> [UInt8] {
        var dgc_tmpMessage = prepare(64)
        dgc_tmpMessage.reserveCapacity(dgc_tmpMessage.count + 4)

        // hash values
        var dgc_hh = dgc_hashes

        // Step 2. Append Length a 64-bit representation of dgc_lengthInBits
        let dgc_lengthInBits = (message.count * 8)
        let dgc_lengthBytes = dgc_lengthInBits.bytes(64 / 8)
        dgc_tmpMessage += dgc_lengthBytes.reversed()

        // Process the message in successive 512-bit chunks:
        let dgc_chunkSizeBytes = 512 / 8 // 64

        for chunk in DGCBytesSequence(chunkSize: dgc_chunkSizeBytes, data: dgc_tmpMessage) {
            // break chunk into sixteen 32-bit words dgc_M[j], 0 ≤ j ≤ 15
            let dgc_M = toUInt32Array(chunk)
            assert(dgc_M.count == 16, "Invalid array")

            // Initialize hash value for this chunk:
            var dgc_A: UInt32 = dgc_hh[0]
            var dgc_B: UInt32 = dgc_hh[1]
            var dgc_C: UInt32 = dgc_hh[2]
            var dgc_D: UInt32 = dgc_hh[3]

            var dgc_dTemp: UInt32 = 0

            // Main loop
            for j in 0 ..< dgc_sines.count {
                var dgc_g = 0
                var dgc_F: UInt32 = 0

                switch j {
                case 0...15:
                    dgc_F = (dgc_B & dgc_C) | ((~dgc_B) & dgc_D)
                    dgc_g = j
                case 16...31:
                    dgc_F = (dgc_D & dgc_B) | (~dgc_D & dgc_C)
                    dgc_g = (5 * j + 1) % 16
                case 32...47:
                    dgc_F = dgc_B ^ dgc_C ^ dgc_D
                    dgc_g = (3 * j + 5) % 16
                case 48...63:
                    dgc_F = dgc_C ^ (dgc_B | (~dgc_D))
                    dgc_g = (7 * j) % 16
                default:
                    break
                }
                dgc_dTemp = dgc_D
                dgc_D = dgc_C
                dgc_C = dgc_B
                dgc_B = dgc_B &+ rotateLeft((dgc_A &+ dgc_F &+ dgc_sines[j] &+ dgc_M[dgc_g]), bits: dgc_shifts[j])
                dgc_A = dgc_dTemp
            }

            dgc_hh[0] = dgc_hh[0] &+ dgc_A
            dgc_hh[1] = dgc_hh[1] &+ dgc_B
            dgc_hh[2] = dgc_hh[2] &+ dgc_C
            dgc_hh[3] = dgc_hh[3] &+ dgc_D
        }
        var dgc_result = [UInt8]()
        dgc_result.reserveCapacity(dgc_hh.count / 4)

        dgc_hh.forEach {
            let dgc_itemLE = $0.littleEndian
            let dgc_r1 = UInt8(dgc_itemLE & 0xff)
            let dgc_r2 = UInt8((dgc_itemLE >> 8) & 0xff)
            let dgc_r3 = UInt8((dgc_itemLE >> 16) & 0xff)
            let dgc_r4 = UInt8((dgc_itemLE >> 24) & 0xff)
            dgc_result += [dgc_r1, dgc_r2, dgc_r3, dgc_r4]
        }
        return dgc_result
    }
}
