#!/bin/sh

# switch caseのシフトなし版
# swiftformat --exclude Carthage,Pods,Generated --stripunusedargs closure-only --decimalgrouping 3 --disable redundanttype,redundantRawValues,redundantSelf,trailingCommas,wrapMultilineStatementBraces,blankLinesAroundMark $1

# switch caseのシフトあり版
swiftformat --exclude Carthage,Pods,Generated --stripunusedargs closure-only --indentcase true --decimalgrouping 3 --disable redundanttype,redundantRawValues,trailingCommas,wrapMultilineStatementBraces,blankLinesAroundMark $1

# 2022/9/3 --extensionacl on-declarations を削除


# 【disable】
# redundanttype 型推論できる不必要な型などを削除する
# redundantRawValues enum の不必要な raw string value を削除する。
# redundantSelf self を挿入または削除する。
# trailingCommas コレクションリテラルの最後の項目の末尾のコンマを追加または削除する。
# wrapMultilineStatementBraces 複数行のステートメントの開始括弧の位置を一段下げる。(if / guard / while / func)
# blankLinesAroundMark Insert blank line before and after MARK: comments.

# 参考：https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md
