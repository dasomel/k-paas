# Failed to restart containerd.service: Unit containerd.service not found.


echo "$CA_CERT" > /usr/local/share/ca-certificates/k-paas.io.crt && update-ca-certificates && for cr in crio containerd; do if [ $(systemctl is-enabled $cr 2> /dev/null) ]; then systemctl restart "$cr"; fi; done




# 아래 내역 cp-cert-setup config 반영
echo "$CA_CERT" > /usr/local/share/ca-certificates/k-paas.io.crt && update-ca-certificates && for cr in crio containerd; do systemctl list-unit-files --type=service | grep -q "^${cr}.service" && systemctl restart "$cr"; done


echo "$CA_CERT" > /usr/local/share/ca-certificates/k-paas.io.crt && update-ca-certificates && for cr in crio; do if [ $(systemctl is-enabled $cr 2> /dev/null) ]; then systemctl restart "$cr"; fi; done