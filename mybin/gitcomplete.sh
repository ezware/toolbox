branches=$(git branch -r | grep -v '\->')
for b in $branches
do
    echo "Tracking branch $b"
    git branch --track "${b#origin/}" "$b"
done
