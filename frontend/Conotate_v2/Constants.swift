//
//  Constants.swift
//  ConotateMacOS
//

import Foundation

struct Constants {
    static let today = Date().timeIntervalSince1970
    static let yesterday = today - 86400
    static let lastWeek = today - (86400 * 5)
    
    static let defaultSections: [Section] = [
        Section(
            id: "notes",
            name: "Notes",
            createdAt: today,
            updatedAt: today,
            tags: ["#general", "#daily", "#log"],
            description: "A collection of general thoughts, reminders, and daily logs. This section serves as a catch-all for information that needs to be recorded quickly."
        ),
        Section(
            id: "ideas",
            name: "Ideas",
            createdAt: today,
            updatedAt: today,
            tags: ["#brainstorm", "#innovation", "#future"],
            description: "Sparks of creativity and potential projects. This section contains raw concepts, \"what if\" scenarios, and early-stage planning for future endeavors."
        ),
        Section(
            id: "tasks",
            name: "Tasks",
            createdAt: today,
            updatedAt: today,
            tags: ["#todo", "#urgent", "#work"],
            description: "Actionable items and to-do lists. This section tracks pending responsibilities, deadlines, and operational tasks requiring attention."
        ),
        Section(
            id: "unsorted",
            name: "Unsorted",
            createdAt: today,
            updatedAt: today,
            tags: ["#uncategorized"],
            description: "Notes that couldn't be automatically classified with high confidence. Review and organize these manually."
        )
    ]
    
    static let initialNotes: [Note] = [
        Note(
            id: "d1",
            text: "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.",
            sectionId: "ideas",
            createdAt: today,
            updatedAt: today
        ),
        Note(
            id: "d2",
            text: "But I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born.",
            sectionId: "notes",
            createdAt: today,
            updatedAt: today
        ),
        Note(
            id: "d3",
            text: "At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti.",
            sectionId: "notes",
            createdAt: yesterday,
            updatedAt: yesterday
        ),
        Note(
            id: "d4",
            text: "Finish the quarterly report documentation by Friday.",
            sectionId: "tasks",
            createdAt: yesterday,
            updatedAt: yesterday
        ),
        Note(
            id: "d5",
            text: "Schedule a meeting with the design team regarding the new icon set.",
            sectionId: "tasks",
            createdAt: lastWeek,
            updatedAt: lastWeek
        ),
        Note(
            id: "d6",
            text: "What if we could categorize notes automatically using local LLMs?",
            sectionId: "ideas",
            createdAt: lastWeek,
            updatedAt: lastWeek
        ),
        Note(
            id: "d7",
            text: "Remember to water the plants in the office. The fern looks a bit dry.",
            sectionId: "notes",
            createdAt: today - 10000,
            updatedAt: today - 10000
        ),
        Note(
            id: "d8",
            text: "Great quote from the meeting: \"Simplicity is the ultimate sophistication.\"",
            sectionId: "notes",
            createdAt: today - 20000,
            updatedAt: today - 20000
        ),
        Note(
            id: "d9",
            text: "Mobile app concept: A social network for introverts where you interact by sending signals instead of messages.",
            sectionId: "ideas",
            createdAt: yesterday - 10000,
            updatedAt: yesterday - 10000
        ),
        Note(
            id: "d10",
            text: "Review the pull requests for the new feature branch.",
            sectionId: "tasks",
            createdAt: today + 5000,
            updatedAt: today + 5000
        ),
        Note(
            id: "d11",
            text: "Update the project roadmap with Q4 milestones.",
            sectionId: "tasks",
            createdAt: yesterday - 50000,
            updatedAt: yesterday - 50000
        )
    ]
    
    static let placeholders = [
        "You type, we organize.",
        "Type / to select commands.",
        "Cmd + Enter to save, Cmd + Shift + Enter to search."
    ]
}
