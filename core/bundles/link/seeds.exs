# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Core.Repo.insert!(%Link.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
#
#
student_count = 1500
researcher_count = 100
researchers_per_study = 5
lab_count = 200
survey_count = 600
time_slots_per_lab = 20
seats_per_time_slot = 20

survey_url = "https://vuamsterdam.eu.qualtrics.com/jfe/form/SV_4Po8iTxbvcxtuaW"

images = [
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1600614908054-57142d1eec2b%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=seonghojang95&name=Seongho+Jang&blur_hash=LKLy%5B%2AMd0L%3FG%3B0XSE2xDyC%25f%24zI%3B",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1615884465870-85b936e70330%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=allthestories&name=Stori%C3%A8s&blur_hash=LMD9q%5BxuNGV%4000WBs%3Boz-qs%3As%3AR%2A",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1619035712435-a04e435edd4d%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=kirchhkreative&name=David+Kirchner&blur_hash=LOD%2BJ94%3A5%3B%3Dv0L%252rqozkrxDt7Io",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1623093177725-639e36469032%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=sjanelle&name=Sarah+Janelle&blur_hash=L69GR14%3A0z%25gTKRk%3DxNI56%25MjGV%40",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1624431403074-c83ccfe2475f%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=lukacskrisztina&name=Luk%C3%A1cs+Krisztina&blur_hash=LPEV%7B14noxt7~p9F%253t7ohITxbbH",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625080232707-722c9539124f%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=theshuttervision&name=Jonathan+Cooper&blur_hash=LVIhmWxuMxRj_NWBxuWB%25gS%24W.oz",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625088863595-59ef8d1fa12c%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=kevinwolf&name=Kevin+Wolf&blur_hash=LuLzEXozWBof~qxaWCay%25MRkoLay",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625125887424-ac3d7b1b96b5%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=timmossholder&name=Tim+Mossholder&blur_hash=LHCG%7DLIUHYt6%40ZI%3ATxsAH%40xaWCkW",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625153806634-28fc701e0499%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=sblaps&name=Scandinavian+Biolabs&blur_hash=LBO%7CeEozogj%5B~qofRkWBS5aeIUt7",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625220966725-4d43a556c7ba%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=andrew_haimerl&name=Andrew+Haimerl&blur_hash=LDCqK9%7DI5hEdNtS3jua%7D5g-E%3DgNY",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625265861167-d72dee66b913%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=chuko&name=Chuko+Cribb&blur_hash=LD9H2_-%3BIUIU00IUxuxu%3FbxuM%7BWB",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625267640835-93159f268cb9%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=vitormonthay&name=Vitor+Monthay&blur_hash=LUIz%40qWXayj%5Bp%7Boff6j%5BF%7Doej%40fk",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625301840042-f9323a348b62%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=markusspiske&name=Markus+Spiske&blur_hash=LIAwxN%2529ED%25pIxvRiIU4TNG%25h%25M",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625323906339-e6d57833ab3d%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=bbiddac&name=BBIDDAC+%E2%9C%A8&blur_hash=LB7%2Ci9Rk0%24xsOqWCrst69_oK-TWC",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625398523918-e525414db705%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=sebastianmark&name=Sebastian+Mark&blur_hash=LaLIpC1i%2CJ%24k%7Czn-SdJj5%2A%24fJ%24JP",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625425280013-3d7e38f88fd0%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=reddalec&name=Redd&blur_hash=LI9Zl%24t79uxa%252oeR%2Aj%5B0fRj-VNH",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625429911820-6039a76bd2f2%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=marekpiwnicki&name=Marek+Piwnicki&blur_hash=LdI464%24%23%24%25j%40~BkAbIs.%5EhX8kBW%3B",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625442634318-04e28fd12782%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=kalaniparker&name=Kellen+Riggin&blur_hash=LoH1%3D9-oIUxC~A-qRkt7%25ht7RjbH",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625482107418-828242ae20be%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=kristapsungurs&name=Kristaps+Ungurs&blur_hash=LvI%3Bq-WYIoWB~WWXf6js%3FHWXs%3Aj%5B",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625520997045-e3c7366ff76e%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=thisbaptista&name=Baptista+Ime+James&blur_hash=LFB.%3DcxFkWIp0%23WB%252R%2AS%25Ip%252%24%2A",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625523214628-4dec27885b68%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=kristapsungurs&name=Kristaps+Ungurs&blur_hash=LsHB-.n%24WCt7_NWAayof%3FaRjRjWB",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625590619376-90b9fc3e8fc9%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=gleblucky&name=Gleb+Lucky&blur_hash=LxF~s_RjtRj%5B_4ayofj%5Bx%5Dofaeae",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625602006137-f50c8e2e72b6%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=lackingnothing&name=Parker+Coffman&blur_hash=LEC~SCx%5BMwv%7D9Zwu%3D%7B-%3A0g-UxuIo",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625653769024-e3173efc4c6d%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=rubercuber&name=Ruben+Frivold&blur_hash=LTH_%23-~VwvsA-%3BS4S2oetmW%3Dj%5BWX",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625664241434-4a0d28032988%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=rylomedia&name=Ryan+Loughlin&blur_hash=LGB%3Aphoe%25MNG%3FwM%7BxuRjoNIoofWB",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625670332473-a91cc3f06766%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=thelifeofdev&name=Devon+Hawkins&blur_hash=L~Mj%3AhR-R%2Aof_NayayazWAayj%5BWB",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625672705429-48bb88df3c07%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=weareambitious&name=Ambitious+Creative+Co.++-+Rick+Barrett&blur_hash=LEGkg%5E595Dx%5DrpxuR%2An%24DNtPI.RP",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625685218928-84b31dc343fa%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=_iammax&name=Maximilian+Zahn&blur_hash=LMDcdgM%7B9aoI%3FwoexZNGb_t7RPt7",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625691988243-535762feee61%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=derickray&name=Derick+McKinney&blur_hash=LaJ%2An%3D-qW%3BR%2AITxut7t7_NWCxaxb",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625706982596-3c1cc516744c%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=vitormonthay&name=Vitor+Monthay&blur_hash=LIFEu%3DWX9baeIpxYxZWq0f%24%25f%2BNb",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625739839403-115ced427495%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=gbcaptured&name=Gelmis+Bartulis&blur_hash=LdP6%5Di%25M%25MRj%3FbRjf6WB~qM%7CM%7Bt7",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625762183076-471915509461%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=gaspo3&name=gaspar+zaldo&blur_hash=LA9s%7C%5E01-%3BIV%3FGD%25%3FaNGfkxaaKa%7C",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625775021321-01a40460b775%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=bullettrainnnnn&name=Oleg+Kryzhanovskyi&blur_hash=L96an--oIoV%40xuxaoJay0fIp%252t7",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625804863005-f69d16bd09e4%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=ryanbyrne&name=Ryan+Byrne&blur_hash=LoHvbT%24%25EMkB%3DdoLR%2BfQ0%23NbxZn%25",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625826961950-7a6bc29fdf57%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=ngocntmn&name=Minh+Ng%E1%BB%8Dc&blur_hash=LeI%7DCK%5E%25~V%25L%5E%25D%2As%3AWV%3D%7BM%7CRkxa",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625857695225-ddd5f160c064%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=rubercuber&name=Ruben+Frivold&blur_hash=LYLEWqIUIUIU~qWBjsaypJWWWVj%5B",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625859133277-8a0833ae984a%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=kerry_hu&name=Kerry+Hu&blur_hash=LLJHs%5BIoIUae~qM%7BV%40aeRkof%252Rj",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625910729129-a1a7e6095ec7%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=dayee&name=%E5%A4%A7%E7%88%B7+%E6%82%A8&blur_hash=LUDJt_WVR%2Ajs%3FwWVWCayS4oeWBj%5D",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625912720286-07e38d6689a7%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=msohebzaidi&name=Soheb+Zaidi&blur_hash=LOAc_F%25NM%7BR%2A_Nx%5DRPni%25%23xvVsWB",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625913952228-8d3fcc4ff5ac%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=andrew_haimerl&name=Andrew+Haimerl&blur_hash=LM7A%24PsqabkE%257juf5j%5DacWVkEad",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625924461741-e9b9ace57daf%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=eyespeak&name=Louisse+Lemuel+Enad&blur_hash=LVCZ%40Uxt8%5EM%7CMvWB%25Nt7M_ofxuWA",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1625941195536-c21885e3e8b2%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=zhpix&name=Pascal+Meier&blur_hash=LIC6omRk4oof-ooMM%7Baz01of-%3Bay",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626014318477-fda0efaaf3d8%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=fkaregan&name=Samuel+Regan-Asante&blur_hash=LNL%7B9%23xFNGxZ2bkWoJNb5%2CWXWVo0",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626024550745-6a1d664f73a5%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=bullettrainnnnn&name=Oleg+Kryzhanovskyi&blur_hash=L78%7D3-IUIUxu%25gxuayof00xu%25MRj",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626049728199-0aa4eeefb2e1%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=kalenemsley&name=Kalen+Emsley&blur_hash=LD9Z%2Bfi_Inozo%23RjWBs%3B0Jt7xuRj",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626073191564-f2257e44b965%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=star7a&name=Edwin+Chen&blur_hash=LcJk4VoKAcfQR4j%5BpJj%5B0Lj%5B%23%2Aa%7D",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626125903674-2ab25abf3030%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=timumphreys&name=Tim+Umphreys&blur_hash=L68%3B77-m0eXn4n9a-%3AaL4TSk-pa0",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626186282285-d7b87d60e867%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=kjenkz&name=Korie+Jenkins&blur_hash=LNA%2CUlad0KtR%3FbjED%25g4xwWAROkD",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626285954411-1b94da59b998%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=karsten116&name=Karsten+Winegeart&blur_hash=LKE.qm-%3AE%25xa%251-%3BoMRj0yjY%24iIo",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626286031129-aa1e2c113dc9%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=karsten116&name=Karsten+Winegeart&blur_hash=LnHoqIozRjo%23_4ozR%2CbIMyt7M%7CRj",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626336496111-d111e6139943%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=chuko&name=Chuko+Cribb&blur_hash=L%2CGlO%5DkDRjt7~qkDWAog%25MkCjsWC",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626341457473-a78bf16272fa%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=davidclode&name=David+Clode&blur_hash=LG5OXAWBIRoft8fQW9fjDzoexxWB",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626379801357-537572de4ad6%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=madalyncox&name=Madalyn+Cox&blur_hash=LJK%2C%3FH0zERRjNFE2E1kCEf9FNHad",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626497994786-88b134bd4a83%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=naomi_august&name=Naomi+August&blur_hash=LxH.QbD%2Aadt700sSozR%2BxuxuozV%40",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626497994786-88b134bd4a83%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=naomi_august&name=Naomi+August&blur_hash=LxH.QbD%2Aadt700sSozR%2BxuxuozV%40",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626515728846-d09aacfee23d%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=patrick_janser&name=Patrick+Janser&blur_hash=LhEUlh%251ofoe-Vs%3AoLj%5B0%23RljZay",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626546557620-6083b26916c8%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=shoots_of_bapt_&name=Baptiste&blur_hash=L44-X.NI10%24%24ENs.xYR%2C10xF%3DwNI",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626554539583-b8ac93f9159e%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=byfoul&name=Frankie+Cordoba&blur_hash=LDGu%2Cm_3~qxu_3WBfQayRjRjWBt7",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626609106372-ddad9ce60404%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=92designed&name=Christina+Deravedisian&blur_hash=LDBfz%2B%3FGofof~Vt6WVj%5BWDayayay",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626617977270-d7adb351c13d%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=chuttersnap&name=CHUTTERSNAP&blur_hash=LiKUs4IU4n%252~qWAR%25WBIBt7xuRj",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626631047919-3ebbbb76ddf3%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=purzlbaum&name=Claudio+Schwarz&blur_hash=L4D%5DuMt8-%3BM%7BtjRjt7M%7B8%5EofRiWA",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626696691538-77d05aab5baf%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=melonbelon&name=J+Lyu&blur_hash=LhKK~I%25M%25hRO_Nxtt6aeWUoejZtR",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626743715381-fe28d408ae3e%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=jayson_hinrichsen&name=Jayson+Hinrichsen&blur_hash=LKD9q%7BnMV%3FRk%3FwaKRiNHE2WVRjWV",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626827793937-a7897ded0424%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=tanleemarquis&name=Tanner+Marquis&blur_hash=LPD9%23O~qM%7BD%25xuayRjj%5BIURjt7ay",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626857719664-92a9b08d5a58%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=drskdr&name=Dasha+Yukhymyuk&blur_hash=LTF%3D~%3F%25ND%25.8D%25t7t7ay00M%7Bt7IU",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626861932431-737a6c4bca98%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=emmaou&name=Emma+Ou&blur_hash=LWL%3B4D0jE4kBM%7DM~a%23%25INHIqD-t3",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626926594516-0d884ec13614%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=zinco&name=Raul+De+Los+Santos&blur_hash=LGCG77Dh%251sS0Ks%3AxuWB4.tRR%2BNH",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626947245642-3e6dafa921fd%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=rcsalbum&name=Debashis+RC+Biswas&blur_hash=LA7.i%5Dj%5B8%24j%3FR%2BfPovkBH_ayt5j%5B",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1626978772479-a31d318224de%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=heftiba&name=Toa+Heftiba&blur_hash=LJA%5D%7BO9FM%7Cs.RkoLoLoe0K-%3BxaWC",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627020730845-1efa46677f0e%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=lgnwvr&name=LOGAN+WEAVER&blur_hash=LBECUm-%3DD%25_3H%3FR5V%3Fxa00s9o%7D9F",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627032171075-ed4c3c0ea490%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=r1ot&name=Yafiu+Ibrahim&blur_hash=Lc6wvFt%2CR4WBHYV%5Btlofxti_Rjbb",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627092611011-36459563a538%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=isaacmartin&name=Isaac+Martin&blur_hash=L23bdo%3D%7CDiD%24WYj%5BxZxZ0eEL%25g-%3B",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627140111251-efb505594a9b%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=jorikkleen&name=Jorik+Kleen&blur_hash=LUG%5BZnM%7BMx-%3B~WWAMxx%5DR-f5IVbc",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627244714766-94dab62ed964%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=nublson&name=Nubelson+Fernandes&blur_hash=L45g%7C%3F~CaHITNgI%5BM%7BRi54Int9xc",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627272145449-1cfd030037e7%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=jayson_hinrichsen&name=Jayson+Hinrichsen&blur_hash=LGFFd9w%5B~q_3%5E%2BD%25NeNH%3FbM_%25Lxa",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627301044065-fc950957c311%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=smithy_512&name=Ethan+Smith&blur_hash=LJLqX%3D_3D%25t7_NofR%2Bae%3FvITxtxu",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627346980717-02226f9ff7f6%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=tanleemarquis&name=Tanner+Marquis&blur_hash=L99%3F2t6M0eR%2AC5%3BOELs.56Na%5EjXS",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627361793048-a3550d91b34f%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=grievek1610begur&name=Kevin+Grieve&blur_hash=LQGJBL9FD%25oe8%5ERPtRRP4T%25goft7",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627382046740-15bf3a1a1fe7%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=galen_crout&name=Galen+Crout&blur_hash=LNIOnV9Z%3Fcnh~W%25MxuoK%25h-pxaSh",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627400334996-d9b4550a1516%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=sixteenmilesout&name=Sixteen+Miles+Out&blur_hash=LAHUwoxu_3-p~o-%3DIUbbM~RiD%24jG",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627433488375-61f25ad84e29%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=jxk&name=Jan+Kop%C5%99iva&blur_hash=LaL4mGRjt7xt3FD%2Axuoftmt7RjRk",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627481639106-2020e8d6ab20%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=andrew_haimerl&name=Andrew+Haimerl&blur_hash=LPDklIxZ5SjF0~R%2B-7fkELa%7Dozf%2B",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627552245715-77d79bbf6fe2%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=eberhardgross&name=eberhard+%F0%9F%96%90+grossgasteiger&blur_hash=LGEfA-~VNItRWVkW%25L%25LIpn%24IUt7",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627597324431-911a27b10899%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=s_midili&name=serjan+midili&blur_hash=LNFFa5R%2A%25gof0Kj%5Bj%5Bay%25hf6sVay",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627616031178-6ba663540b98%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=ralphkayden&name=Ralph+%28Ravi%29+Kayden&blur_hash=LaF62lV%3D0eIVRkoJs%3Ao2RQt7aKt7",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627627045944-a6171e94783a%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=phillipgold&name=Phillip+Goldsberry&blur_hash=LXF68%40ogW%3DoJ~qWBRjfPRjM%7BRiWB",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627631502740-db08f1bd686c%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=markbasarabvisuals&name=Mark+Basarab&blur_hash=LXEU.CIpW%3BoL%251oLWqay0g-oWCWV",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627651522140-94cf2e2a5ac0%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5OTM%26ixlib%3Drb-1.2.1&username=721y&name=chutipon+youngcharoen&blur_hash=L142C%2B%5ElHqD%25Y%2APUR4ml0%7Bo%23-pvz",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627673680358-b43bbf96f6f1%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDc5MzY%26ixlib%3Drb-1.2.1&username=reisgekkie&name=Gwenn+Klabbers&blur_hash=LYE%7B%25%3FIVs%3AkClVxaWBayo%23RjbIfQ",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1627682315217-2913898b6af8%3Fixid%3DMnwyMTY0MzZ8MHwxfHJhbmRvbXx8fHx8fHx8fDE2Mjc4MDgwNTk%26ixlib%3Drb-1.2.1&username=sushimi&name=Susanna+Marsiglia&blur_hash=LLNmi%7CxG9a%3Fw_N.9NF%3FIIqM_Ri%3Fc"
]

password = "asdf;lkjASDF0987"

_member =
  Core.Factories.insert!(:member, %{
    email: "member@eyra.co",
    password: password
  })

_admin =
  Core.Factories.insert!(:member, %{
    email: "admin@example.org",
    password: password
  })

researcher =
  Core.Factories.insert!(:member, %{
    researcher: true,
    email: "researcher@eyra.co",
    password: password
  })

{:ok, students} =
  Core.Repo.transaction(fn ->
    for _ <- 1..student_count do
      Core.Factories.insert!(:member)
    end
  end)

{:ok, researchers} =
  Core.Repo.transaction(fn ->
    for _ <- 1..researcher_count do
      Core.Factories.insert!(:member, %{researcher: true})
    end
  end)

{:ok, labs} =
  Core.Repo.transaction(fn ->
    for _ <- 1..lab_count do
      number_of_seats = :random.uniform(time_slots_per_lab)
      reservation_count = :random.uniform(number_of_seats)

      %{
        type: :lab_tool,
        promotion: %{
          title: Faker.Lorem.sentence() <> " (lab)",
          subtitle: Faker.Lorem.sentence(),
          description: Faker.Lorem.paragraph(),
          image_id: Enum.random(images),
          marks: ["vu"],
          plugin: "lab"
        },
        lab_tool: %{
          time_slots:
            for _ <- 0..:random.uniform(time_slots_per_lab) do
              %{
                start_time: Faker.DateTime.forward(365) |> DateTime.truncate(:second),
                location: Faker.Lorem.sentence(),
                number_of_seats: number_of_seats,
                reservations:
                  Enum.take_random(students, reservation_count)
                  |> Enum.map(&%{user: &1, status: :reserved})
              }
            end
        }
      }
    end
  end)

{:ok, surveys} =
  Core.Repo.transaction(fn ->
    for _ <- 1..survey_count do
      %{
        type: :survey_tool,
        promotion: %{
          title: Faker.Lorem.sentence() <> " (survey)",
          subtitle: Faker.Lorem.sentence(),
          description: Faker.Lorem.paragraph(),
          image_id: Enum.random(images),
          marks: ["vu"],
          plugin: "survey"
        },
        survey_tool: %{
          survey_url: Faker.Internet.url(),
          # desktop_enabled: true,
          # phone_enabled: true,
          # tablet_enabled: true,
          subject_count: 56,
          duration: "a while"
        }
      }
    end
  end)

studies = labs ++ surveys

Core.Repo.transaction(
  fn ->
    for study_data <- studies do
      study =
        Core.Factories.insert!(:study, %{
          title: study_data.promotion.title,
          description: ""
        })

      tool_content_node = Core.Factories.insert!(:content_node)
      {tool_type, study_data} = Map.pop!(study_data, :type)
      {tool_data, study_data} = Map.pop!(study_data, tool_type)
      {promotion_data, study_data} = Map.pop!(study_data, :promotion)

      promotion =
        Core.Factories.insert!(
          :promotion,
          Map.merge(
            %{
              parent_content_node: tool_content_node,
              study: study,
              submission:
                Core.Factories.build(:submission, %{
                  parent_content_node: tool_content_node,
                  status: :accepted
                })
            },
            promotion_data
          )
        )

      tool =
        Core.Factories.insert!(
          tool_type,
          Map.merge(
            %{content_node: tool_content_node, study: study, promotion: promotion},
            tool_data
          )
        )

      if tool_type == :survey_tool do
        participant_count = :random.uniform(tool.subject_count)

        for student <- Enum.take_random(students, participant_count) do
          Core.Survey.Tools.apply_participant(tool, student)
        end
      end

      for owner <- Enum.take_random(researchers, max(:random.uniform(researchers_per_study), 1)) do
        Core.Authorization.assign_role(
          owner,
          study,
          :owner
        )
      end

      Core.Authorization.assign_role(
        researcher,
        study,
        :owner
      )
    end
  end,
  timeout: :infinity
)
