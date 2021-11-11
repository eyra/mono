import Config

config :banking_proxy, banking_backend: Bunq

config :banking_proxy,
  backend_params: [
    endpoint: "https://public-api.sandbox.bunq.com/v1",
    private_key: """
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEA10jqhE5lMKigNQ9/ntIx7pm2vZQlTWaT9iXKMxUxGNIiTiRZ
    0c+wF/kvj+1ZxNNm+Pe17S/LJ1mdiKugQAZsuw9q6bof/64h37aI4WdCMaXi54It
    4cHBIizgGeydxzF1xeyYOPlmQYdbOBaPjPMijv2X507AkZ7O8BqYH9Cm2kQ3I8+G
    6Zknd63PJ1/ydxebdII1/fa2tQ1mDmvrrxYQ6BqUUJD5bDvJ9KIQLP4ZRnGHIT0e
    eYdPscwHC3J4u5rCUCAQFnuJ6tI9b1Eq1VVbyFaT7HQR1WZdLN4ZxUaOdZbV1x4v
    Sh0HM56uRbHkpCZgRt38nBhMlcD7zS98tyU0cQIDAQABAoIBAHTKELdf1BNWlzrR
    wpkFTKM07mbgFHBt4nzZOV0G9RCTBps/qx5gPhZzTzMUPuvBB46uyxn2II6jVgvL
    l27ETX4ZOhW7rBpHfAbh/lXRb56BcJvJClz7gGuqzpQhweJK2apa1KWr3qZT6M9/
    pbaAO9I4joykM2GMNpUYyEgSKEIlWtDAQ69rngmSCzoITNmZMwX9KnJrod+OVBuF
    3LaZMNRiBeDWnLOUilt1XbgAYuJjNP/GY+lr8GyUGX0ECO/PfR1WojlqfrE01ZkF
    a48vPs11BjH6jmWdWeUOpH5ZXj4WXqfYw64926EaFvu5sMieDgAVUCuN1IdI0qVT
    YTVtUHECgYEA6/Ygwi5jaUXZTj9fZLOKfcuRGzHjsQjA7MI1gRZ8DqRiPCP5F84s
    msZtLaVr79c0uIsFV4ofxVBsE4gNqeebKxGuwW0XL+MTgU7qx2vf7fk8DKScoc5s
    A8flFisSb+Bi7SMAYphpU0zCEhJG4gxplc0J2jUrqMUwOvEqyH0ldO0CgYEA6ZFF
    wMQdYzNKjN9665Kse+nRLoAx1pg+a7ul4sqAetyjd98y1vsaR97+5OVZh9W+UeVD
    KdI8ebFrUCsvBTjRJeMtiC3XIIz48fzLE4DiJk9cSTvXD3tCyjk9dyYs6ijnD0oi
    25Wz1VHXhM7FgoAgzTm6NfAhVwNeqOyB42uOcRUCgYEAiuPlhGcpvN2Qe65xyCSm
    cEVStF85VwuAA9yNAd7qRvQbnqrOBGUnfDMwMJ4eWp6iOb4a9twmt04PT6/V2xyp
    CUDvTIuaCmXvJT3+lEO7G6iI4ChEyjlm+xK+lb3krFW35T2lDGQKGy4jTd/UOVp1
    C+gU1IxXlo/7Q7aRKFIBqkECgYBGuNoqGDfdxbYZGcIaensHujDAp8hvdgHQlS0R
    ksd8bDqDHW5DchzvDjKYFGobmzjZi1Xe3+2322TnDWxbZGzP0A4FYfv1uznV6/mB
    mlDf0L/c3OWtpmD+4n4eCc0nyeLM2mHbo2SkfveHGyTq8uj7uzMLCf7OXhLXi2V4
    +yRSUQKBgQDMrY/S+Ct+dr58A/k0Ma5UGuK/M8n6cdjAeB9e859ZY+kmdDD5Lk+G
    RaIlg4kQOK8hmJAR09HtRjEQI57QTxCdvG/RNnUy71LGBiuRaiKLkAoZBdeUa9sG
    MmhUIUKaLJn45AtSoJ+/Ihsxch7UDJz00DviIl8jtkH7KnhGhpMtZw==
    -----END RSA PRIVATE KEY-----
    """,
    iban: "NL60BUNQ2058107543",
    api_key: "sandbox_6c3121f8bf6a2332a7b25cc1aef472f7f74baa54a9a689b7b0fe2e38",
    installation_token: "be7ea406261b01efe25fb43ef8ef16f4600a423e84a03a22c8ea91fe5b373297 ",
    device_id: "253221"
  ],
  certfile: "/home/jeroen/Downloads/sslgen/ssl-gen/certs/localhost.pem",
  cacertfile: "/home/jeroen/Downloads/sslgen/ssl-gen/certs/eyra-cert.pem",
  keyfile: "/home/jeroen/Downloads/sslgen/ssl-gen/certs/localhost.key"
