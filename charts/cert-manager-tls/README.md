# Cert Manager TLS

Generates cert-manager Certificate and/or Issuer manifests

## Inputs

| Name                                     | Default                    | Description                                                 |
| ---------------------------------------- | -------------------------- | ----------------------------------------------------------- |
| `apiVersion`                             | `cert-manager.io/v1alpha2` | The cert-manager api version to use for resources           |
| `commonLabels`                           | `{}`                       | Common labels to apply to all resources                     |
| `commonAnnotations`                      | `{}`                       | Common annotations to apply to all reasources               |
| `certificates`                           | `{}`                       | Map of certificates to generate. The key is the object name |
| `issuers`                                | `{}`                       | Map of issuers to generate. The key is the object name.     |
| `certificates.<certificate>.labels`      | `{}`                       | Labels to apply to this certificate                         |
| `certificates.<certificate>.annotations` | `{}`                       | Annotations to apply to this certificate                    |
| `issuers.<issuer>.labels`                | `{}`                       | Labels to apply to this issuer                              |
| `issuers.<issuer>.annotations`           | `{}`                       | Annotations to apply to this issuer                         |

## Certificates

Certificate definitions require at least `issuerRef` and `secretName` be set as well as one of
`dnsNames`, `uris` or `ipAddresses`.

The definition must be a valid [cert-manager Certificate spec](https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.CertificateSpec)

```yaml
certificates:
  example:
    secretName: example-tls
    issuerRef:
      name: letsencrypt-production
      kind: ClusterIssuer
    dnsNames:
      - example.tools.{{ env `GLADLY_CLUSTER_ID` }}

  example-ca:
    secretName: example-ca-tls
    commonName: example-ca
    isCa: true
    issuerRef:
      name: example-selfsigned
    usages: [signing]
```

## Issuers

Issuer definitions require at least `name` to be defined. `kind` will default to `Issuer` if not set.

The remainder of the definition must be a valid [cert-manager Issuer spec](https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.IssuerSpec)

```yaml
issuers:
  example-cluster-issuer:
    kind: ClusterIssuer
    email: user@example.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: example-issuer-account-key
    solvers:
      - http01:
          ingress:
            class: nginx

  example-selfsigned:
    selfSigned: {}

  example-ca:
    ca:
      secretName: example-ca-tls
```
