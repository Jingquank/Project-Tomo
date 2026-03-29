import Foundation
import SwiftData
import UIKit

enum DummyDataSeeder {

    // #region agent log
    private static func _dbg(_ msg: String, _ data: [String: Any] = [:], hyp: String, loc: String) {
        let p = "/Users/keding/Code/Project-Tomo/.cursor/debug-1a8c24.log"
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        var e: [String: Any] = ["sessionId":"1a8c24","timestamp":ts,"location":loc,"message":msg,"hypothesisId":hyp]
        if !data.isEmpty { e["data"] = data }
        if let j = try? JSONSerialization.data(withJSONObject: e), let s = String(data: j, encoding: .utf8) {
            let line = s + "\n"
            if FileManager.default.fileExists(atPath: p), let h = FileHandle(forWritingAtPath: p) {
                h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); h.closeFile()
            } else { FileManager.default.createFile(atPath: p, contents: line.data(using: .utf8)) }
        }
    }
    // #endregion

    private static func loadDummyImage(_ name: String) -> Data? {
        // #region agent log
        let jpgPath = Bundle.main.path(forResource: name, ofType: "jpg")
        let pngPath = Bundle.main.path(forResource: name, ofType: "png")
        let resolvedPath = jpgPath ?? pngPath
        let img: UIImage? = resolvedPath.flatMap { UIImage(contentsOfFile: $0) }
        let allBundleImages = (try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath))?.filter { $0.contains("dummy") } ?? []
        _dbg("loadDummyImage", [
            "name": name,
            "jpgPath": jpgPath ?? "nil",
            "pngPath": pngPath ?? "nil",
            "imgNil": img == nil,
            "bundleDummyFiles": allBundleImages
        ], hyp: "H5,H6", loc: "DummyDataSeeder.swift:loadDummyImage")
        let data = img?.jpegData(compressionQuality: 0.8)
        return data
        // #endregion
    }

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Friend>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        // #region agent log
        _dbg("seedIfNeeded called", ["existingCount": count, "willSeed": count == 0], hyp: "H1", loc: "DummyDataSeeder.swift:seedIfNeeded")
        // #endregion
        guard count == 0 else { return }

        seedCheshireMiao(context: context)
        seedEdHirthe(context: context)
        seedGertrudeYost(context: context)
        try? context.save()
    }

    @MainActor
    private static func seedCheshireMiao(context: ModelContext) {
        let imageData = loadDummyImage("dummy-cheshire")
        let friend = Friend(name: "Cheshire Miao", thumbnailData: imageData)
        context.insert(friend)

        let thumbnail = Story(textContent: "", isPinned: true, isThumbnailStory: true)
        thumbnail.imageData = imageData
        thumbnail.friend = friend

        let nameStory = Story(textContent: "Cheshire Miao", isPinned: true, isNameStory: true)
        nameStory.friend = friend

        let bioStory = Story(textContent: "Cheshire was born on Apr 6, 1995. She is currently living in Guangzhou. Her type of MBTI is INFJ.")
        bioStory.createdAt = makeDate(month: 12, year: 2024)
        bioStory.lastEditedAt = bioStory.createdAt
        bioStory.isPinned = true
        bioStory.magicalEntities = [
            MagicalEntity(type: .birthday, value: "Apr 6, 1995", label: "Birthday", startIndex: 22, endIndex: 33, isConfirmed: true),
            MagicalEntity(type: .location, subtype: "currentCity", value: "Guangzhou", label: "Current city", startIndex: 62, endIndex: 71, isConfirmed: true),
            MagicalEntity(type: .mbti, value: "INFJ", label: "MBTI", startIndex: 93, endIndex: 97, isConfirmed: true),
        ]
        bioStory.friend = friend

        let dueDate = Story(textContent: "Cheshire is due by July 7, 2025.")
        dueDate.createdAt = makeDate(month: 1, year: 2025)
        dueDate.lastEditedAt = dueDate.createdAt
        dueDate.magicalEntities = [
            MagicalEntity(type: .importantDate, subtype: "Due date", value: "July 7, 2025", label: "Cheshire is due", startIndex: 19, endIndex: 31, isConfirmed: true),
        ]
        dueDate.friend = friend

        let moomin = Story(textContent: "Likes Moomin.")
        moomin.createdAt = makeDate(month: 12, year: 2024)
        moomin.lastEditedAt = moomin.createdAt
        moomin.friend = friend

        let quote = Story(textContent: "\u{201C}I would read Tove Jansson\u{2019}s book for my beloved kid.\u{201D}")
        quote.createdAt = makeDate(month: 1, year: 2024)
        quote.lastEditedAt = quote.createdAt
        quote.friend = friend

        let crochet = Story(textContent: "Learning crochet recently.")
        crochet.createdAt = makeDate(month: 1, year: 2024)
        crochet.lastEditedAt = crochet.createdAt
        crochet.friend = friend

        [thumbnail, nameStory, bioStory, dueDate, moomin, quote, crochet].forEach { context.insert($0) }
    }

    @MainActor
    private static func seedEdHirthe(context: ModelContext) {
        let imageData = loadDummyImage("dummy-ed")
        let friend = Friend(name: "Ed Hirthe", thumbnailData: imageData)
        context.insert(friend)

        let thumbnail = Story(textContent: "", isPinned: true, isThumbnailStory: true)
        thumbnail.imageData = imageData
        thumbnail.friend = friend

        let nameStory = Story(textContent: "Ed Hirthe", isPinned: true, isNameStory: true)
        nameStory.friend = friend

        let link = Story(textContent: "Shared a link to an article about sustainable architecture in Copenhagen.")
        link.createdAt = makeDate(month: 3, year: 2024)
        link.lastEditedAt = link.createdAt
        link.friend = friend

        let coffee = Story(textContent: "Prefers oat milk lattes. Always orders the same thing.")
        coffee.createdAt = makeDate(month: 11, year: 2023)
        coffee.lastEditedAt = coffee.createdAt
        coffee.friend = friend

        [thumbnail, nameStory, link, coffee].forEach { context.insert($0) }
    }

    @MainActor
    private static func seedGertrudeYost(context: ModelContext) {
        let imageData = loadDummyImage("dummy-gertrude")
        let friend = Friend(name: "Gertrude Yost", thumbnailData: imageData)
        context.insert(friend)

        let thumbnail = Story(textContent: "", isPinned: true, isThumbnailStory: true)
        thumbnail.imageData = imageData
        thumbnail.friend = friend

        let nameStory = Story(textContent: "Gertrude Yost", isPinned: true, isNameStory: true)
        nameStory.friend = friend

        let toronto = Story(textContent: "Visiting Toronto on May 10, 2026.")
        toronto.createdAt = makeDate(month: 2, year: 2025)
        toronto.lastEditedAt = toronto.createdAt
        toronto.magicalEntities = [
            MagicalEntity(type: .location, subtype: "Visiting", value: "Toronto", label: "Visiting", startIndex: 9, endIndex: 16, isConfirmed: true),
            MagicalEntity(type: .importantDate, subtype: "Important date", value: "May 10, 2026", label: "Visiting Toronto", startIndex: 20, endIndex: 32, isConfirmed: true),
        ]
        toronto.friend = friend

        let writing = Story(textContent: "Gertrude is writing a collection of short stories called Whispers from Wallbury.")
        writing.createdAt = makeDate(month: 1, year: 2024)
        writing.lastEditedAt = writing.createdAt
        writing.friend = friend

        [thumbnail, nameStory, toronto, writing].forEach { context.insert($0) }
    }

    private static func makeDate(month: Int, year: Int) -> Date {
        var components = DateComponents()
        components.month = month
        components.year = year
        components.day = 15
        return Calendar.current.date(from: components) ?? Date()
    }
}
