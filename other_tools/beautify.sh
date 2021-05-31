
#Add space after comma
#remove space before comma `,`
#remove space before semicolon `;`
find . -type f -name '*.[ch]' -exec sed -i 's/,\([a-zA-Z0-9]\)/, \1/g;s/[ ]\+,/,/g;s/[ ]\+;/;/g' {} +

#remove space before parentheses `(`, `)`
find . -type f -name '*.[ch]' -exec sed -i 's/[ ]\+\(/\(/g;s/[ ]\+\)/\)/g' {} +

#add space between keyword and parentheses `(`
find . -type f -name '*.[ch]' -exec sed -i 's/\([ \t]\+\)\(if|while\)\(/\1\2 \(/g' {} +

#Add space before key words
find . -type f -name '*.[ch]' -exec sed -i 's/ \(if|while|do\)(/ \1 (/g' {} +

#Add space before *
find . -type f -name '*.[ch]' -exec sed -i 's/\([a-zA-Z0-9]\)\*/\1 */g' {} +
