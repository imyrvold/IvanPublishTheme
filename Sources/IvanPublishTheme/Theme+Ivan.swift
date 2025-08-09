//
//  Theme+Ivan.swift
//  Copyright (c) Ivan C Myrvold 2020
//
//  Created by Ivan C Myrvold on 28/11/2020.
//


import Plot
import Publish
import Foundation

// Shared date formatter for Ivan theme
private let ivanDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateStyle = .medium
    return formatter
}()

private func formatDate(_ date: Date) -> String {
    ivanDateFormatter.string(from: date)
}

public extension Theme {

    static var ivan: Self {
        Theme(
            htmlFactory: IvanHTMLFactory(),
            resourcePaths: ["Resources/IvanTheme/styles.css"]
        )
    }
}

private struct IvanHTMLFactory<Site: Website>: HTMLFactory {
    func makeIndexHTML(for index: Index,
                       context: PublishingContext<Site>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: index, on: context.site),
            .body(
                .header(for: context, selectedSection: nil),
                .div(
                    .class("hero"),
                    .div(
                        .class("hero-content"),
                        .h1(.text(index.title)),
                        .p(
                            .class("description"),
                            .text(context.site.description)
                        ),
                        .a(
                            .class("cta"),
                            .href("/"),
                            .text("Browse posts ↓")
                        )
                    )
                ),
                .wrapper(
                    .h2("Latest content"),
                    .itemList(
                        for: context.allItems(
                            sortedBy: \.date,
                            order: .descending
                        ),
                        on: context.site
                    )
                ),
                .footer(for: context.site)
            )
        )
    }

    func makeSectionHTML(for section: Section<Site>,
                         context: PublishingContext<Site>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: section, on: context.site),
            .body(
                .header(for: context, selectedSection: section.id),
                .wrapper(
                    .h1(.text(section.title)),
                    .itemList(for: section.items, on: context.site)
                ),
                .footer(for: context.site)
            )
        )
    }

    func makeItemHTML(for item: Item<Site>,
                      context: PublishingContext<Site>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: item, on: context.site),
            .body(
                .class("item-page"),
                .header(for: context, selectedSection: item.sectionID),
                .wrapper(
                    .article(
                        .h1(.text(item.title)),
                        .p(
                            .class("meta"),
                            .text(formatDate(item.date))
                        ),
                        .div(
                            .class("content"),
                            .contentBody(item.body)
                        ),
                        .div(
                            .class("post-tags"),
                            .span("Tagged with: "),
                            .tagList(for: item, on: context.site)
                        )
                    )
                ),
                .footer(for: context.site)
            )
        )
    }

    func makePageHTML(for page: Page,
                      context: PublishingContext<Site>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site),
            .body(
                .header(for: context, selectedSection: nil),
                .wrapper(

                ),
                .footer(for: context.site)
            )
        )
    }

    func makeTagListHTML(for page: TagListPage,
                         context: PublishingContext<Site>) throws -> HTML? {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site),
            .body(
                .header(for: context, selectedSection: nil),
                .wrapper(
                    .h1("Browse all tags"),
                    .ul(
                        .class("all-tags"),
                        .forEach(page.tags.sorted()) { tag in
                            .li(
                                .class("tag"),
                                .a(
                                    .href(context.site.path(for: tag)),
                                    .text(tag.string)
                                )
                            )
                        }
                    )
                ),
                .footer(for: context.site)
            )
        )
    }

    func makeTagDetailsHTML(for page: TagDetailsPage,
                            context: PublishingContext<Site>) throws -> HTML? {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site),
            .body(
                .header(for: context, selectedSection: nil),
                .wrapper(
                    .h1(
                        "Tagged with ",
                        .span(.class("tag"), .text(page.tag.string))
                    ),
                    .a(
                        .class("browse-all"),
                        .text("Browse all tags"),
                        .href(context.site.tagListPath)
                    ),
                    .itemList(
                        for: context.items(
                            taggedWith: page.tag,
                            sortedBy: \.date,
                            order: .descending
                        ),
                        on: context.site
                    )
                ),
                .footer(for: context.site)
            )
        )
    }
}

private extension Node where Context == HTML.BodyContext {
    static func wrapper(_ nodes: Node...) -> Node {
        .div(.class("wrapper"), .group(nodes))
    }

    static func header<T: Website>(
        for context: PublishingContext<T>,
        selectedSection: T.SectionID?
    ) -> Node {
        let sectionIDs = T.SectionID.allCases

        return .header(
            .wrapper(
                .a(.class("site-name"), .href("/"), .text(context.site.name)),
                .if(sectionIDs.count > 1,
                    .nav(
                        .ul(.forEach(sectionIDs) { section in
                            .li(
                                .a(
                                    .class(section == selectedSection ? "selected" : ""),
                                    .href(context.sections[section].path),
                                    .text(context.sections[section].title)
                                )
                            )
                        })
                    )
                )
            )
        )
    }

    static func itemList<T: Website>(for items: [Item<T>], on site: T) -> Node {
        return .ul(
            .class("item-list"),
            .forEach(items) { item in
                let daysSince = Calendar.current.dateComponents([.day], from: item.date, to: Date()).day ?? 999
                let isNew = daysSince <= 14
                return .li(
                    .article(
                        .h1(
                            .a(
                                .href(item.path),
                                .text(item.title)
                            )
                        ),
                        .p(
                            .class("meta"),
                            .group([
                                .text(formatDate(item.date)),
                                .if(isNew, .span(.class("badge new"), .text("NEW")))
                            ])
                        ),
                        .tagList(for: item, on: site),
                        .p(.text(item.description))
                    )
                )
            }
        )
    }

    static func tagList<T: Website>(for item: Item<T>, on site: T) -> Node {
        return .ul(.class("tag-list"), .forEach(item.tags) { tag in
            .li(.a(
                .href(site.path(for: tag)),
                .text(tag.string)
            ))
        })
    }

    static func footer<T: Website>(for site: T) -> Node {
        return .footer(
            .p(
                .text("Generated using "),
                .a(
                    .text("Publish"),
                    .href("https://github.com/johnsundell/publish")
                )
            ),
            .p(
                .a(
                    .text("RSS feed"),
                    .href("/feed.rss")
                ),
                .text(" | "),
                .a(
                    .text("Twitter"),
                    .href("https://twitter.com/imyrvold"),
                    .target(.blank)
                ),
                .text(" | "),
                .a(
                    .text("GitHub"),
                    .href("https://github.com/imyrvold"),
                    .target(.blank)
                )
            )
        )
    }
}
