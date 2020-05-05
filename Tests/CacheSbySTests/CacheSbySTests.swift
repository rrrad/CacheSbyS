import XCTest
@testable import CacheSbyS

final class CacheSbySTests: XCTestCase {
    var date:(() -> Date?)!
    var timeInterval: TimeInterval?
    var maximumCountLimit: Int!
    
    var sut: Cache<Int, String>!
    
    var arrKeys: Array = [Int]()
          

    override func setUp() {
       // цыкл для заполнения arrKeys
        for i in 1...20 {
            arrKeys.append(i)
        }
        date = {return nil}
        timeInterval = nil
        maximumCountLimit = 2
        
        sut = Cache<Int, String>(dateProvider: date, entryLifeTime: timeInterval, maximumCountLimit: maximumCountLimit)

    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testInitialisation() {
        XCTAssertNotNil(sut)
    }
    
    func testInsertDataInCache() {
        let data = randomData()
        let key = randomKey()

        sut.insert(data, for: key)
        
        XCTAssertEqual(data, sut[key])
    }
    
    
    
    func testGetDataFromCache() {
        let data = randomData()
        let key = randomKey()

        let responsEmpty = sut.value(forKey: key)
        XCTAssertEqual(responsEmpty, nil)
        
        sut.insert(data, for: key)
        
        let responsFull = sut.value(forKey: key)
        XCTAssertEqual(data, responsFull)

    }
    
    func testReplaceDataFromCache() {
        let data = randomData()
        let key = randomKey()
        let data2 = randomData()

        sut.insert(data, for: key)
        
        let responsFull = sut.value(forKey: key)
        XCTAssertEqual(data, responsFull)
        
        sut.insert(data2, for: key)
        
        let responsFull2 = sut.value(forKey: key)
        XCTAssertEqual(data2, responsFull2)
    
    }
    
    func testRemoveDataFromCache() {
        let data = randomData()
        let key = randomKey()
        let data2 = randomData()
        let key2 = randomKey()

        
        sut.insert(data, for: key)
        sut.insert(data2, for: key2)
        
        let responsFull = sut.value(forKey: key)
        XCTAssertEqual(data, responsFull)
        
        let responsFull2 = sut.value(forKey: key2)
        XCTAssertEqual(data2, responsFull2)
        
        sut.removeValue(forKey: key)
        let responsEmpty = sut.value(forKey: key)
        let responsNoEmpty = sut.value(forKey: key2)
        XCTAssertEqual(responsEmpty, nil)
        XCTAssertEqual(responsNoEmpty, data2)
    }
    
    //MARK: - test with expiration date
    func testForLimitCount() {
        let data = randomData()
        let key = randomKey()
        let data2 = randomData()
        let key2 = randomKey()
        let data3 = randomData()
        let key3 = randomKey()
        let data4 = randomData()
        let key4 = randomKey()

        
        sut.insert(data, for: key)
        sut.insert(data2, for: key2)
        sut.insert(data3, for: key3)
        
        XCTAssertNil(sut[key])
        XCTAssertEqual(data2, sut[key2])
        XCTAssertEqual(data3, sut[key3])
        
        sut.insert(data4, for: key4)
        
        XCTAssertNil(sut[key2])
        XCTAssertEqual(data3, sut[key3])
        XCTAssertEqual(data4, sut[key4])
    }
    
    func testForExpirationTimeForData() {
        var d = Date()
        date = {return d}
        timeInterval = 2
        
        let data = randomData()
        let key = randomKey()
        sut = Cache<Int, String>(dateProvider: date, entryLifeTime: timeInterval)

        
        sut.insert(data, for: key)
        XCTAssertEqual(data, sut[key])
        
        d.addTimeInterval(3.0)
        XCTAssertNil(sut[key])
    }
    
    
    //MARK: - test save data
    func testEncodeDecodeCache() throws {
        let data = randomData()
        let key = randomKey()
        let data2 = randomData()
        let key2 = randomKey()

        sut.insert(data, for: key)
        sut.insert(data2, for: key2)
        
        let encodedSut = try JSONEncoder().encode(sut)
        XCTAssertNotNil(encodedSut)
        let decodedSut = try JSONDecoder().decode(Cache<Int, String>.self, from: encodedSut)
        XCTAssertEqual(sut[key], decodedSut[key])
        XCTAssertEqual(sut[key2], decodedSut[key2])
    }

    func testSaveDataToDisk() throws {
        let nameFile = "testfile"
        let fm = FileManager.default
        let folders = fm.urls(for: .cachesDirectory, in: .userDomainMask)
        let fileURL = folders[0].appendingPathComponent(nameFile + ".cache")
        XCTAssertFalse(fm.fileExists(atPath: fileURL.absoluteString))
        
        try sut.saveToDisk(withName: nameFile)
        XCTAssertNotNil(fm.fileExists(atPath: fileURL.absoluteString))
        addTeardownBlock {
            do {
                try fm.removeItem(at: fileURL)
            } catch let err {
                print(err.localizedDescription)
            }
        }
}
    
    static var allTests = [
        ("testExample", testInitialisation),
    ]
}

extension CacheSbySTests {
    func randomKey() -> Int {
        let returnedIndex = Int.random(in: 0...arrKeys.count - 1)
        let returnedValue = arrKeys[returnedIndex]
        arrKeys.remove(at: returnedIndex)
        return returnedValue
    }
    
    func randomData() -> String {
        let set = "qwertyuiopasdfghjklzxcvbnm"
        let count = set.count
        var res = ""
        for _ in 1...8 {
            let index = Int.random(in: 0...count-1)
            let sindex = set.index(set.startIndex, offsetBy: index)
            let l = set[sindex]
            res.append(l)
        }
        return res
    }
}
