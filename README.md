ICTSC9 予選練習用ネットワーク
============================

# なにこれ
Linuxカーネルの機能を使って仮想のネットワークを仕立てて、トラブルシューティングしてもらいます。

# 使い方
`sudo ./ex_net.sh up` で作って、`sudo ./ex_net.sh down` で片付けられます。
詰んだときも一旦片付ければなんとかなるはずです。

# 仮想ノード(netns)への入り方
`ip netns exec [node_name] [command]` でいけます。
`[node_name]` は `ip netns` でわかります。




