defmodule OPPClient do
  use OPPClient.Helper

  defmodule OPPResponses do
  end

  @base_url "https://api-sandbox.onlinebetaalplatform.nl/v1"

  # @api_key "79eeea74cb5685779ac17f5758ddc5e0"

  def new(opts \\ []) do
    [
      base_url: @base_url
    ]
    |> Keyword.merge(opts)
    |> Req.new()
  end

  def_req(:post, "/merchants",
    type: [
      type: {:in, ["consumer", "business"]}
    ],
    country: [
      # TODO: Download ISO list on build:
      # https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.json
      type: {:in, ["nld"]},
      required: true
    ],
    emailaddress: [
      type: :string,
      required: true
    ],
    notify_url: [
      type: :string,
      required: true
    ]
  )

  def_req(:get, "/merchants/{{merchant_uuid}}")

  def_req(:post, "/transactions",
    merchant_uid: [type: :string, required: true],
    locale: [type: {:in, ["nl", "en", "fr", "de"]}],
    total_price: [type: :pos_integer, required: true],
    products: [
      type:
        {:list,
         {:map,
          [
            name: [type: :string, required: true],
            quantity: [type: :pos_integer, required: true],
            price: [type: :pos_integer, required: true]
          ]}},
      required: true
    ],
    return_url: [type: :string, required: true],
    notify_url: [type: :string, required: true],
    metadata: [type: :map]
  )

  def_req(:post, "/merchants/{{merchant_uid}}/withdrawals",
    amount: [type: :pos_integer, required: true],
    currency: [type: :string],
    partner_fee: [type: :pos_integer],
    notify_url: [type: :string, required: true],
    description: [type: :string, required: true],
    reference: [type: :string],
    metadata: [type: :map]
  )

  def_req(:post, "/charges",
    type: [type: {:in, ["balance"]}, required: true],
    amount: [type: :pos_integer, required: true],
    currency: [type: :string],
    description: [type: :string],
    payout_description: [type: :string],
    to_owner_uid: [type: :string, required: true],
    from_owner_uid: [type: :string, required: true],
    metadata: [type: :string]
  )

  # create
  # retrieve
  # update
  # delete

  #   type string 	Merchant type. One of:
  # consumerbusiness
  # country string 	Country code of the merchant,
  # use ISO 3166-1 alpha-3 country code.
  # locale string 	The language in which the text on the verification screens is being displayed and tickets are sent. Default is en
  # One of:
  # nl en fr de
  # name_first string 	First name of the merchant. ( CONSUMER ONLY! )
  # name_last string 	Last name of the merchant. ( CONSUMER ONLY! )
  # is_pep boolean 	Whether or not the merchant is a PEP. This will mark the contact that is automatically created as a PEP. ( CONSUMER ONLY! )
  # coc_nr string 	Chamber of Commerce number of the merchant.
  # up to 45 characters
  # nullable
  # ( BUSINESS ONLY! )
  # vat_nr string 	Value added tax identification number.
  # up to 45 characters
  # ( BUSINESS ONLY! )
  # legal_name string 	(Business) Name of the merchant.
  # up to 45 characters
  # legal_entity string 	Business entity of the merchant. One of the legal_entity_code from the legal entity list ( BUSINESS ONLY! )
  # trading_names array 	Array with one or more trading names.

  # name
  # string

  # Trading name.
  # emailaddress string 	Email address of the merchant.
  # Must be unique for every merchant.
  # phone string 	Phone number of the merchant.
  # settlement_interval string 	The settlement interval of the merchant. Default is set contractually. Can only be provided after agreement with OPP.
  # One of:
  # daily weekly monthly yearly continuous
  # notify_url string 	URL to which the notifications of the merchant will be sent.
  # return_url string 	URL to which the merchant will be directed when closing the verification screens.
  # metadata object with key-value pairs 	Additional data that belongs to the merchant object.
  # addresses array 	Address array of the merchant with name/value pairs.

  # 200 	OK 	Success
  # 400 	Bad Request 	Missing parameter(s)
  # 401 	Unauthorized 	Invalid or revoked API key
  # 404 	Not Found 	Resource doesn't exist
  # 409 	Conflict 	Conflict due to concurrent request
  # 410 	Gone 	Resource doesn't exist anymore
  # 50X 	Server Errors 	Temporary problem on our side

  # api_key (env var)

  #   API Status

  #     Example request - Status check

  # curl https://api-sandbox.onlinebetaalplatform.nl/status \
  #     -H "Authorization: Bearer {{api_key}}"

  #     Example response

  # {
  #     "status": "online",
  #     "date": 1611321273
  # }

  # Idempotency-Key: {key}

  #   Pagination

  #     Example request - Retrieve page 2 of the transactions list:

  # curl https://api-sandbox.onlinebetaalplatform.nl/v1/transactions?page=2&perpage=10 \
  #     -H "Authorization: Bearer {{api_key}}"

  #     Example response:

  # {
  #     "livemode": true,
  #     "object": "list",
  #     "url": "/v1/transactions",
  #     "has_more": true,
  #     "total_item_count": 259,
  #     "items_per_page": 10,
  #     "current_page": 2,
  #     "last_page": 26,
  #     "data": []
  # }

  # When retrieving lists of objects, OPP creates pages to keep the transferred objects small. Use the pagination functionality to navigate when sorting through many results. The pages can be switched by adding the following parameters to the GET call:
  # Parameter 	Description
  # page integer 	The number of the current page.
  # perpage integer 	The limit of objects to be returned. Limit can range between 1 and 100 items.
end
