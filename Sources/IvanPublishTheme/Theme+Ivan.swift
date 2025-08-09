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
                        .p(
                            .class("meta"),
                            .text(formatDate(item.date))
                        ),
                        .div(
                            .class("content"),
                            .contentBody(item.body)
                        ),
                        // --- Insert reactions bar, login, comment UI here ---
                        .div(.id("reactions")),
                        .p(.id("loginStatus")),
                        .button(.id("googleLogin"), .text("Sign in with Google")),
                        .form(
                            .id("commentForm"),
                            .div(
                                .attribute(named: "style", value: "margin: 12px 0; display:flex; gap:8px;"),
                                .input(
                                    .id("commentInput"),
                                    .attribute(named: "placeholder", value: "Write a comment"),
                                    .attribute(named: "aria-label", value: "Comment"),
                                    .attribute(named: "style", value: "flex:1; padding:8px 10px; border-radius:10px; border:1px solid #ddd;")
                                ),
                                .button(
                                    .attribute(named: "type", value: "submit"),
                                    .text("Post Comment")
                                )
                            )
                        ),
                        .ul(.id("commentsList")),
                        .div(
                            .class("post-tags"),
                            .span("Tagged with: "),
                            .tagList(for: item, on: context.site)
                        ),
                        // --- Firebase script at the end of .article ---
                        .script(
                            .attribute(named: "type", value: "module"),
                            .raw("\n  import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.0.1/firebase-app.js';\n  import { getAuth, signInAnonymously, GoogleAuthProvider, signInWithPopup, onAuthStateChanged } from 'https://www.gstatic.com/firebasejs/11.0.1/firebase-auth.js';\n  import { getFirestore, doc, getDoc, setDoc, updateDoc, increment, collection, addDoc, onSnapshot, serverTimestamp, query, orderBy } from 'https://www.gstatic.com/firebasejs/11.0.1/firebase-firestore.js';\n\n  // Replace with your Firebase project configuration\n  const firebaseConfig = {\n    apiKey: 'AIzaSyD8EfYviwYi-qUE2DShj3mU6ImQ8nmZ-vI',\n    authDomain: 'irina-blogger.firebaseapp.com',\n    projectId: 'irina-blogger',\n    storageBucket: 'irina-blogger.firebasestorage.app',\n    messagingSenderId: '638468652170',\n    appId: '1:638468652170:web:f6874b54adcd7296cc8173'\n  };\n\n  const app = initializeApp(firebaseConfig);\n  const auth = getAuth(app);\n  const db = getFirestore(app);\n  let currentUser = null;\n\n  // Use the path as a stable post id (e.g. /posts/my-article)\n  const postId = window.location.pathname;\n\n  // Ensure an auth session exists (anonymous by default)\n  signInAnonymously(auth).catch(console.error);\n\n  const loginStatus = document.getElementById('loginStatus');\n  const reactionsDiv = document.getElementById('reactions');\n  const googleBtn = document.getElementById('googleLogin');\n  const commentsList = document.getElementById('commentsList');\n  const commentForm = document.getElementById('commentForm');\n  const commentInput = document.getElementById('commentInput');\n\n  onAuthStateChanged(auth, (user) => {\n    if (!user) return;\n    currentUser = user;\n    loginStatus.textContent = user.isAnonymous ? 'You are browsing anonymously' : `Logged in as ${user.displayName || user.email}`;\n  });\n\n  // Optional Google sign-in\n  googleBtn?.addEventListener('click', async () => {\n    try {\n      const provider = new GoogleAuthProvider();\n      await signInWithPopup(auth, provider);\n    } catch (e) { console.error(e); }\n  });\n\n  // Emoji reactions (customize the set as you wish)\n  const emojis = ['👍','😂','❤️','🎣'];\n  for (const emoji of emojis) {\n    const ref = doc(db, `posts/${postId}/reactions/${emoji}`);\n    const snap = await getDoc(ref);\n    let count = snap.exists() ? snap.data().count : 0;\n\n    const btn = document.createElement('button');\n    btn.textContent = `${emoji} ${count}`;\n    btn.style.marginRight = '8px';\n    btn.style.padding = '6px 10px';\n    btn.style.borderRadius = '999px';\n\n    btn.onclick = async () => {\n      try {\n        await setDoc(ref, { count: increment(1) }, { merge: true });\n      } catch (e) { console.error(e); }\n    };\n\n    reactionsDiv.appendChild(btn);\n\n    // Live updates for each emoji\n    onSnapshot(ref, (docSnap) => {\n      if (docSnap.exists()) {\n        btn.textContent = `${emoji} ${docSnap.data().count}`;\n      }\n    });\n  }\n\n  // Comments: submit\n  commentForm?.addEventListener('submit', async (e) => {\n    e.preventDefault();\n    if (!currentUser) return;\n    const text = (commentInput?.value || '').trim();\n    if (!text) return;\n    try {\n      await addDoc(collection(db, `posts/${postId}/comments`), {\n        text,\n        userName: currentUser.displayName || 'Anonymous',\n        userId: currentUser.uid,\n        createdAt: serverTimestamp()\n      });\n      commentInput.value = '';\n    } catch (e) { console.error(e); }\n  });\n\n  // Live comments feed (newest first)\n  const q = query(collection(db, `posts/${postId}/comments`), orderBy('createdAt', 'desc'));\n  onSnapshot(q, (snapshot) => {\n    commentsList.innerHTML = '';\n    snapshot.forEach((doc) => {\n      const c = doc.data();\n      const li = document.createElement('li');\n      const when = c.createdAt?.toDate ? c.createdAt.toDate().toLocaleString() : '';\n      li.textContent = `${c.userName || 'Anonymous'}: ${c.text} ${when ? '— ' + when : ''}`;\n      commentsList.appendChild(li);\n    });\n  });\n")
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
