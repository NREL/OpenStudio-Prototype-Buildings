
# Extend the class to add Large Hotel specific stuff
class OpenStudio::Model::Model

  def define_space_type_map(building_type, building_vintage, climate_zone)
    space_type_map = {
        'Banquet' => ['Banquet_Flr_6','Dining_Flr_6'],
        'Basement'=>['Basement'],
        'Cafe' => ['Cafe_Flr_1'],
        'Corridor'=> ['Corridor_Flr_6'],
        'Corridor2'=> ['Corridor_Flr_3'],
        'GuestRoom'=> ['Room_1_Flr_3','Room_2_Flr_3','Room_5_Flr_3','Room_6_Flr_3'],
        'GuestRoom3'=> ['Room_1_Flr_6','Room_2_Flr_6'],
        'GuestRoom2'=> ['Room_3_Mult19_Flr_3','Room_4_Mult19_Flr_3'],
        'GuestRoom4'=> ['Room_3_Mult9_Flr_6'],
        'Kitchen'=> ['Kitchen_Flr_6'],
        'Laundry'=> ['Laundry_Flr_1'],
        'Lobby'=> ['Lobby_Flr_1'],
        'Mechanical'=> ['Mech_Flr_1'],
        'Retail'=> ['Retail_1_Flr_1'],
        'Retail2'=> ['Retail_2_Flr_1'],
        'Storage'=> ['Storage_Flr_1']
    }

    return space_type_map
  end

  def define_minimum_airflow_fraction_map
    minimum_airflow_fraction_map = {
        "90.1-2004" => {
            "ASHRAE 169-2006-4B" => {
                "Basement ZN" => 0.379227102863149,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.926117189918785,
                "Dining_Flr_6 ZN" => 0.885952697066497,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.368271919046961,
                "Kitchen_Flr_6 ZN" => 0.770994631563846,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-4A" => {
                "Basement ZN" => 0.421820969688902,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 1,
                "Dining_Flr_6 ZN" => 0.984950388542523,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.354575741974405,
                "Kitchen_Flr_6 ZN" => 0.744904819056421,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-5B" => {
                "Basement ZN" => 0.438417458195772,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.988213833713432,
                "Dining_Flr_6 ZN" => 0.946234286450854,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.35581191867806,
                "Kitchen_Flr_6 ZN" => 0.780660165945899,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-6A" => {
                "Basement ZN" => 0.445811930083098,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.639296009048406,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 1,
                "Dining_Flr_6 ZN" => 0.997914075382815,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.352167532725179,
                "Kitchen_Flr_6 ZN" => 0.739845570882658,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-5A" => {
                "Basement ZN" => 0.427606518928179,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.61204060051058,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 1,
                "Dining_Flr_6 ZN" => 0.986328125598869,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.355885722610935,
                "Kitchen_Flr_6 ZN" => 0.747656871082283,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-7A" => {
                "Basement ZN" => 0.48047114137998,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.648535777740419,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 1,
                "Dining_Flr_6 ZN" => 0.994045348547266,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.359532757301827,
                "Kitchen_Flr_6 ZN" => 0.755318686020281,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-3B" => {
                "Basement ZN" => 0.371667903397135,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.939082623533956,
                "Dining_Flr_6 ZN" => 0.899241324869832,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.379383522332814,
                "Kitchen_Flr_6 ZN" => 0.794761493818916,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-8A" => {
                "Basement ZN" => 0.526989928858432,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.656591927391221,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 1,
                "Dining_Flr_6 ZN" => 1,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.329021996909191,
                "Kitchen_Flr_6 ZN" => 0.760371239433141,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-6B" => {
                "Basement ZN" => 0.433081040455825,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.600196167588603,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.980674089538545,
                "Dining_Flr_6 ZN" => 0.937963033070143,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.358527648396051,
                "Kitchen_Flr_6 ZN" => 0.793142180556312,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-2A" => {
                "Basement ZN" => 0.403968152219682,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 1,
                "Dining_Flr_6 ZN" => 0.968826167538949,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.341976421729661,
                "Kitchen_Flr_6 ZN" => 0.76333683575343,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-3A" => {
                "Basement ZN" => 0.400370420041665,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 1,
                "Dining_Flr_6 ZN" => 0.968968756933558,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.354350367964599,
                "Kitchen_Flr_6 ZN" => 0.744431345645466,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-1A" => {
                "Basement ZN" => 0.356524662039753,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 1,
                "Dining_Flr_6 ZN" => 0.972991895758454,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.354888000877729,
                "Kitchen_Flr_6 ZN" => 0.74556082321673,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-2B" => {
                "Basement ZN" => 0.403605910825493,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.973763454545404,
                "Dining_Flr_6 ZN" => 0.936745710005998,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.3,
                "Kitchen_Flr_6 ZN" => 0.821613991718121,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-4C" => {
                "Basement ZN" => 0.459731671734418,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.644733138410456,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 1,
                "Dining_Flr_6 ZN" => 1,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.356829403481944,
                "Kitchen_Flr_6 ZN" => 0.749639388060324,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-3C" => {
                "Basement ZN" => 0.471805790834291,
                "Retail_2_Flr_1 ZN" => 0.500887236154628,
                "Storage_Flr_1 ZN" => 0.680759032094585,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 1,
                "Dining_Flr_6 ZN" => 1,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.34716461017706,
                "Kitchen_Flr_6 ZN" => 0.72933526046292,
                "Corridor_Flr_6 ZN" => 0.3
            }
        },
        "90.1-2007" => {
            "ASHRAE 169-2006-4B" => {
                "Basement ZN" => 0.39212451714824,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.548930776152036,
                "Kitchen_Flr_6 ZN" => 0.930118425232945,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-4A" => {
                "Basement ZN" => 0.443045959731521,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.607197621598422,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.52288125707153,
                "Kitchen_Flr_6 ZN" => 0.915397941829686,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-5B" => {
                "Basement ZN" => 0.475398136831814,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.531734395969548,
                "Kitchen_Flr_6 ZN" => 0.94990061745912,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-6A" => {
                "Basement ZN" => 0.487995009131651,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.636143424298463,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.519791710384696,
                "Kitchen_Flr_6 ZN" => 0.909989133156462,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-5A" => {
                "Basement ZN" => 0.472941534629741,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.613801921479187,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.52372312136235,
                "Kitchen_Flr_6 ZN" => 0.916871777100493,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-7A" => {
                "Basement ZN" => 0.501084926724255,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.640902969453048,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.52918381224,
                "Kitchen_Flr_6 ZN" => 0.926431701314195,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-3B" => {
                "Basement ZN" => 0.383893495541716,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.552982722972092,
                "Kitchen_Flr_6 ZN" => 0.96809598667022,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-8A" => {
                "Basement ZN" => 0.554539487138276,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.648529825700684,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.487513658091967,
                "Kitchen_Flr_6 ZN" => 0.937770876037954,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-6B" => {
                "Basement ZN" => 0.464201715078115,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.530957075802142,
                "Kitchen_Flr_6 ZN" => 0.964214282747058,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-2A" => {
                "Basement ZN" => 0.414148398151024,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.524389508059948,
                "Kitchen_Flr_6 ZN" => 0.918038407197086,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-3A" => {
                "Basement ZN" => 0.418587419832823,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.522791201174172,
                "Kitchen_Flr_6 ZN" => 0.915240282739832,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-1A" => {
                "Basement ZN" => 0.375573930497083,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.527793050168704,
                "Kitchen_Flr_6 ZN" => 0.923996921485274,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-2B" => {
                "Basement ZN" => 0.404238860926801,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.482588193702815,
                "Kitchen_Flr_6 ZN" => 0.963467025609496,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-4C" => {
                "Basement ZN" => 0.483969669218587,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.639170817275912,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.526868405018542,
                "Kitchen_Flr_6 ZN" => 0.922378163390708,
                "Corridor_Flr_6 ZN" => 0.3
            },
            "ASHRAE 169-2006-3C" => {
                "Basement ZN" => 0.487580964218432,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.672367027056109,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.3,
                "Mech_Flr_1 ZN" => 0.3,
                "Laundry_Flr_1 ZN" => 0.3,
                "Corridor_Flr_3 ZN" => 0.505671550593381,
                "Kitchen_Flr_6 ZN" => 0.885269246879283,
                "Corridor_Flr_6 ZN" => 0.3
            }
        },
        "90.1-2010" => {
            "ASHRAE 169-2006-4B" => {
                "Basement ZN" => 0.450247714166273,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.705050106545427,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.252827152039566,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.513915609795,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.204369728582821
            },
            "ASHRAE 169-2006-4A" => {
                "Basement ZN" => 0.509147484063901,
                "Retail_2_Flr_1 ZN" => 0.533897584812976,
                "Storage_Flr_1 ZN" => 0.771781656026557,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.261697417553729,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.553093282509519,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.225415642985424
            },
            "ASHRAE 169-2006-5B" => {
                "Basement ZN" => 0.548917244721431,
                "Retail_2_Flr_1 ZN" => 0.50800102963058,
                "Storage_Flr_1 ZN" => 0.747602733243649,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.228648305073213,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.506967036038782,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.203874935827675
            },
            "ASHRAE 169-2006-6A" => {
                "Basement ZN" => 0.564228227761974,
                "Retail_2_Flr_1 ZN" => 0.534919118907706,
                "Storage_Flr_1 ZN" => 0.809497384605699,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.250668003062679,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.557264872134716,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.230452172738339
            },
            "ASHRAE 169-2006-5A" => {
                "Basement ZN" => 0.545855635871973,
                "Retail_2_Flr_1 ZN" => 0.52924421309192,
                "Storage_Flr_1 ZN" => 0.781331611762331,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.253888286889459,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.549535584888087,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.227834124273473
            },
            "ASHRAE 169-2006-7A" => {
                "Basement ZN" => 0.58111995497773,
                "Retail_2_Flr_1 ZN" => 0.524570153523082,
                "Storage_Flr_1 ZN" => 0.813653329637928,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.228009429370832,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.528756413890793,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.228875700713437
            },
            "ASHRAE 169-2006-3B" => {
                "Basement ZN" => 0.436826559932134,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.674966964850925,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.27215074752891,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.528718801091491,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.228357526225244
            },
            "ASHRAE 169-2006-8A" => {
                "Basement ZN" => 0.643981625327529,
                "Retail_2_Flr_1 ZN" => 0.521103570974634,
                "Storage_Flr_1 ZN" => 0.814130062120288,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.2,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.468049377175837,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.211913290914505
            },
            "ASHRAE 169-2006-6B" => {
                "Basement ZN" => 0.536862969101692,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.751303939875644,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.221852904822322,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.501379271761366,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.208979994703114
            },
            "ASHRAE 169-2006-2A" => {
                "Basement ZN" => 0.47109573288054,
                "Retail_2_Flr_1 ZN" => 0.525833126334596,
                "Storage_Flr_1 ZN" => 0.721809181605116,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.288554757655531,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.562749076016215,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.242350246954211
            },
            "ASHRAE 169-2006-3A" => {
                "Basement ZN" => 0.476372613410382,
                "Retail_2_Flr_1 ZN" => 0.528902636934935,
                "Storage_Flr_1 ZN" => 0.736539022964778,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.289560492579712,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.568622416071102,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.249855186410228
            },
            "ASHRAE 169-2006-1A" => {
                "Basement ZN" => 0.425782363216542,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.304787507746177,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.522820286066961,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.231735684350132
            },
            "ASHRAE 169-2006-2B" => {
                "Basement ZN" => 0.458517431904395,
                "Retail_2_Flr_1 ZN" => 0.502705973257667,
                "Storage_Flr_1 ZN" => 0.641073490263179,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.232591081374802,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.46955825376463,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.205656561211955
            },
            "ASHRAE 169-2006-4C" => {
                "Basement ZN" => 0.558289791409998,
                "Retail_2_Flr_1 ZN" => 0.531252709827829,
                "Storage_Flr_1 ZN" => 0.815812421791316,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.218768289076886,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.525398735260356,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.221854075313096
            },
            "ASHRAE 169-2006-3C" => {
                "Basement ZN" => 0.561030137055311,
                "Retail_2_Flr_1 ZN" => 0.546726431795365,
                "Storage_Flr_1 ZN" => 0.853111827642211,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.28495134712439,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.551787225783428,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.294350298312061
            }
        },
        "90.1-2013" => {
            "ASHRAE 169-2006-4B" => {
                "Basement ZN" => 0.489955643239496,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.70540212165206,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.260413926342975,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.525016421096233,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.23115240985381
            },
            "ASHRAE 169-2006-4A" => {
                "Basement ZN" => 0.55285436846337,
                "Retail_2_Flr_1 ZN" => 0.533414015877333,
                "Storage_Flr_1 ZN" => 0.772072592105481,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.268638374868001,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.562587405562968,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.253085124009133
            },
            "ASHRAE 169-2006-5B" => {
                "Basement ZN" => 0.564537072568438,
                "Retail_2_Flr_1 ZN" => 0.509596179341101,
                "Storage_Flr_1 ZN" => 0.751506816485701,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.236194220622248,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.518357353576265,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.229710027484099
            },
            "ASHRAE 169-2006-6A" => {
                "Basement ZN" => 0.586098869044823,
                "Retail_2_Flr_1 ZN" => 0.536125384430279,
                "Storage_Flr_1 ZN" => 0.814342050017418,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.258832639609055,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.561028778106187,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.258698562890714
            },
            "ASHRAE 169-2006-5A" => {
                "Basement ZN" => 0.560638722876294,
                "Retail_2_Flr_1 ZN" => 0.530519985547367,
                "Storage_Flr_1 ZN" => 0.784466467972413,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.261862353888157,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.564116156233558,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.255856159769558
            },
            "ASHRAE 169-2006-7A" => {
                "Basement ZN" => 0.609083633494889,
                "Retail_2_Flr_1 ZN" => 0.520366667074757,
                "Storage_Flr_1 ZN" => 0.809656625487667,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.237965846153117,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.528944253246719,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.253726856799019
            },
            "ASHRAE 169-2006-3B" => {
                "Basement ZN" => 0.449452423431406,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.67530304848861,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.28291031760719,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.545800378326767,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.244522194140907
            },
            "ASHRAE 169-2006-8A" => {
                "Basement ZN" => 0.669835608806401,
                "Retail_2_Flr_1 ZN" => 0.51922515065499,
                "Storage_Flr_1 ZN" => 0.812455876413996,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.2,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.477993577924485,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.234141289405278
            },
            "ASHRAE 169-2006-6B" => {
                "Basement ZN" => 0.557942857497753,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.757396251490606,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.230317919050985,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.516744754749437,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.234467174848535
            },
            "ASHRAE 169-2006-2A" => {
                "Basement ZN" => 0.481011426905454,
                "Retail_2_Flr_1 ZN" => 0.517728215881795,
                "Storage_Flr_1 ZN" => 0.715041916933626,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.316319021155836,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.559453261109654,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.267029085825116
            },
            "ASHRAE 169-2006-3A" => {
                "Basement ZN" => 0.48999787200401,
                "Retail_2_Flr_1 ZN" => 0.525275128688571,
                "Storage_Flr_1 ZN" => 0.736755488366032,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.301062987969463,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.561034933946847,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.266976553472036
            },
            "ASHRAE 169-2006-1A" => {
                "Basement ZN" => 0.431295957380611,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.6,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.331816621268626,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.560473413310301,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.271923018953959
            },
            "ASHRAE 169-2006-2B" => {
                "Basement ZN" => 0.46679305861072,
                "Retail_2_Flr_1 ZN" => 0.5,
                "Storage_Flr_1 ZN" => 0.633134319559062,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.258521448696826,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.505865291871721,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.228747239905644
            },
            "ASHRAE 169-2006-4C" => {
                "Basement ZN" => 0.589990582501239,
                "Retail_2_Flr_1 ZN" => 0.533671229133878,
                "Storage_Flr_1 ZN" => 0.823294027920867,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.227787693314201,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.541168389055417,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.247083742072994
            },
            "ASHRAE 169-2006-3C" => {
                "Basement ZN" => 0.580502184952079,
                "Retail_2_Flr_1 ZN" => 0.546706270177742,
                "Storage_Flr_1 ZN" => 0.857163201227389,
                "Cafe_Flr_1 ZN" => 0.9,
                "Lobby_Flr_1 ZN" => 0.64,
                "Banquet_Flr_6 ZN" => 0.88,
                "Dining_Flr_6 ZN" => 0.86,
                "Retail_1_Flr_1 ZN" => 0.303033345376914,
                "Mech_Flr_1 ZN" => 0.2,
                "Laundry_Flr_1 ZN" => 0.2,
                "Corridor_Flr_3 ZN" => 0.54299429433094,
                "Kitchen_Flr_6 ZN" => 0.2,
                "Corridor_Flr_6 ZN" => 0.314466175347322
            }
        }
    }

    return minimum_airflow_fraction_map

  end

  def define_hvac_system_map(building_type, building_vintage, climate_zone)
    system_to_space_map = [
        {
            'type' => 'VAV',
            'space_names' =>
                [
                    'Basement',
                    'Retail_1_Flr_1',
                    'Retail_2_Flr_1',
                    'Mech_Flr_1',
                    'Storage_Flr_1',
                    'Laundry_Flr_1',
                    'Cafe_Flr_1',
                    'Lobby_Flr_1',
                    'Corridor_Flr_3',
                    'Banquet_Flr_6',
                    'Dining_Flr_6',
                    'Corridor_Flr_6',
                    'Kitchen_Flr_6'
                ]
        },
        {
            'type' => 'DOAS',
            'space_names' =>
                [
                    'Room_1_Flr_3','Room_2_Flr_3','Room_3_Mult19_Flr_3','Room_4_Mult19_Flr_3','Room_5_Flr_3','Room_6_Flr_3','Room_1_Flr_6','Room_2_Flr_6','Room_3_Mult9_Flr_6'
                ]
        }
    ]
    return system_to_space_map
  end

  def define_space_multiplier
    # This map define the multipliers for spaces with multipliers not equals to 1
    space_multiplier_map = {
        'Room_1_Flr_3' => 4,
        'Room_2_Flr_3' => 4,
        'Room_3_Mult19_Flr_3' => 76,
        'Room_4_Mult19_Flr_3' => 76,
        'Room_5_Flr_3' => 4,
        'Room_6_Flr_3' => 4,
        'Corridor_Flr_3' => 4,
        'Room_3_Mult9_Flr_6' => 9
    }
    return space_multiplier_map
  end

  def add_hvac(building_type, building_vintage, climate_zone, prototype_input, hvac_standards)
    #simulation_control =  self.getSimulationControl
    #simulation_control.setLoadsConvergenceToleranceValue(0.4)
    #simulation_control.setTemperatureConvergenceToleranceValue(0.5)

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Started Adding HVAC')
    system_to_space_map = define_hvac_system_map(building_type, building_vintage, climate_zone)

    #VAV system; hot water reheat, water-cooled chiller
    chilled_water_loop = self.add_chw_loop(prototype_input, hvac_standards, nil, building_type)
    hot_water_loop = self.add_hw_loop(prototype_input, hvac_standards, building_type)

    system_to_space_map.each do |system|
      #find all zones associated with these spaces
      thermal_zones = []
      system['space_names'].each do |space_name|
        space = self.getSpaceByName(space_name)
        if space.empty?
          OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "No space called #{space_name} was found in the model")
          return false
        end
        space = space.get
        zone = space.thermalZone
        if zone.empty?
          OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "No thermal zone was created for the space called #{space_name}")
          return false
        end
        thermal_zones << zone.get
      end


      minimum_airflow_fraction_map_all = self.define_minimum_airflow_fraction_map
      minimum_airflow_fraction_map = minimum_airflow_fraction_map_all[building_vintage][climate_zone]


      case system['type']
        when 'VAV'
          if hot_water_loop && chilled_water_loop
            self.add_vav(prototype_input, hvac_standards, hot_water_loop, chilled_water_loop, thermal_zones, building_type, minimum_airflow_fraction_map)
          else
            OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', 'No hot water and chilled water plant loops in model')
            return false
          end
        when 'DOAS'
          self.add_doas(prototype_input, hvac_standards, hot_water_loop, chilled_water_loop, thermal_zones, building_type, building_vintage, climate_zone)
        else
          OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "Undefined HVAC system type called #{system['type']}")
          return false
      end
    end

    # Add Exhaust Fan
    space_type_map = define_space_type_map(building_type, building_vintage, climate_zone)
    ['Banquet', 'Kitchen','Laundry'].each do |space_type|
      space_type_data = self.find_object(self.standards['space_types'], {'template'=>building_vintage, 'building_type'=>building_type, 'space_type'=>space_type})
      if space_type_data == nil
        OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "Unable to find space type #{building_vintage}-#{building_type}-#{space_type}")
        return false
      end

      exhaust_schedule = add_schedule(space_type_data['exhaust_schedule'])
      if exhaust_schedule.class.to_s == "NilClass"
        OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "Unable to find Exhaust Schedule for space type #{building_vintage}-#{building_type}-#{space_type}")
        return false
      end
      balanced_exhaust_schedule = add_schedule(space_type_data['balanced_exhaust_fraction_schedule'])

      space_names = space_type_map[space_type]
      space_names.each do |space_name|
        space = self.getSpaceByName(space_name).get
        thermal_zone = space.thermalZone.get

        zone_exhaust_fan = OpenStudio::Model::FanZoneExhaust.new(self)
        zone_exhaust_fan.setName(space.name.to_s + " Exhaust Fan")
        zone_exhaust_fan.setAvailabilitySchedule(exhaust_schedule)
        zone_exhaust_fan.setFanEfficiency(space_type_data['exhaust_fan_efficiency'])
        zone_exhaust_fan.setPressureRise (space_type_data['exhaust_fan_pressure_rise'])
        maximum_flow_rate = OpenStudio.convert(space_type_data['exhaust_fan_maximum_flow_rate'], 'cfm', 'm^3/s').get

        zone_exhaust_fan.setMaximumFlowRate(maximum_flow_rate)
        if balanced_exhaust_schedule.class.to_s != "NilClass"
          zone_exhaust_fan.setBalancedExhaustFractionSchedule (balanced_exhaust_schedule)
        end
        zone_exhaust_fan.setEndUseSubcategory("Zone Exhaust Fans")
        zone_exhaust_fan.addToThermalZone(thermal_zone)
      end
    end

    # Update Sizing Zone
    zone_sizing = self.getSpaceByName('Kitchen_Flr_6').get.thermalZone.get.sizingZone
    zone_sizing.setCoolingMinimumAirFlowFraction(0.7)

    zone_sizing = self.getSpaceByName('Laundry_Flr_1').get.thermalZone.get.sizingZone
    zone_sizing.setCoolingMinimumAirFlow(0.23567919336)

    # Add the daylighting controls for lobby, cafe, dinning and banquet
    self.add_daylighting_controls(building_vintage)

    OpenStudio::logFree(OpenStudio::Info, 'openstudio.model.Model', 'Finished adding HVAC')
    return true
  end #add hvac

  def add_daylighting_controls(building_vintage)
      space_names = ['Banquet_Flr_6','Dining_Flr_6','Cafe_Flr_1','Lobby_Flr_1']
      space_names.each do |space_name|
        space = self.getSpaceByName(space_name).get
        space.addDaylightingControls(building_vintage, false, false)
      end
  end

  def add_swh(building_type, building_vintage, climate_zone, prototype_input, hvac_standards, space_type_map)

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started Adding SWH")

    # Add the main service hot water loop
    swh_space_name = "Basement"
    swh_thermal_zone = self.getSpaceByName(swh_space_name).get.thermalZone.get
    swh_loop = self.add_swh_loop(prototype_input, hvac_standards, 'main',swh_thermal_zone)

    # Add the water use equipment
    guess_room_space_types =['GuestRoom','GuestRoom2','GuestRoom3','GuestRoom4']
    kitchen_space_types = ['Kitchen']
    guess_room_water_use_rate = 0.020833333 # gal/min, Reference: NREL Reference building report 5.1.6
    kitchen_space_use_rate = 2.22 # gal/min, from PNNL prototype building
    guess_room_water_use_schedule = "HotelLarge GuestRoom_SWH_Sch"
    kitchen_water_use_schedule = "HotelLarge BLDG_SWH_SCH"

    water_end_uses = []
    space_type_map = define_space_type_map(building_type, building_vintage, climate_zone)
    space_multipliers = define_space_multiplier

    guess_room_space_types.each do |space_type|
      space_names = space_type_map[space_type]
      space_names.each do |space_name|
        space_multiplier = 1
        space_multiplier= space_multipliers[space_name].to_i if space_multipliers[space_name] != nil
        water_end_uses.push([space_name, guess_room_water_use_rate * space_multiplier,guess_room_water_use_schedule])
      end
    end

    kitchen_space_types.each do |space_type|
        space_names = space_type_map[space_type]
        space_names.each do |space_name|
          space_multiplier = 1
          space_multiplier= space_multipliers[space_name].to_i if space_multipliers[space_name] != nil
          water_end_uses.push([space_name, kitchen_space_use_rate * space_multiplier,kitchen_water_use_schedule])
        end
    end

    self.add_large_hotel_swh_end_uses(prototype_input, hvac_standards, swh_loop, 'main', water_end_uses)

    # Add the laundry water heater
    laundry_water_heater_space_name = "Basement"
    laundry_water_heater_thermal_zone = self.getSpaceByName(laundry_water_heater_space_name).get.thermalZone.get
    laundry_water_heater_loop = self.add_swh_loop(prototype_input, hvac_standards, 'laundry', laundry_water_heater_thermal_zone)
    self.add_swh_end_uses(prototype_input, hvac_standards, laundry_water_heater_loop,'laundry')

    booster_water_heater_space_name = "KITCHEN_FLR_6"
    booster_water_heater_thermal_zone = self.getSpaceByName(booster_water_heater_space_name).get.thermalZone.get
    swh_booster_loop = self.add_swh_booster(prototype_input, hvac_standards, swh_loop, booster_water_heater_thermal_zone)
    self.add_booster_swh_end_uses(prototype_input, hvac_standards, swh_booster_loop)

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished adding SWH")
    return true
  end #add swh

  def add_large_hotel_swh_end_uses(prototype_input, standards, swh_loop, type, water_end_uses)
    puts "Adding water uses type = '#{type}'"
    water_end_uses.each do |water_end_use|
      space_name = water_end_use[0]
      use_rate = water_end_use[1] # in gal/min

      # Water use connection
      swh_connection = OpenStudio::Model::WaterUseConnections.new(self)
      swh_connection.setName(space_name + "Water Use Connections")
      # Water fixture definition
      water_fixture_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(self)
      rated_flow_rate_m3_per_s = OpenStudio.convert(use_rate,'gal/min','m^3/s').get
      water_fixture_def.setPeakFlowRate(rated_flow_rate_m3_per_s)
      water_fixture_def.setName("#{space_name} Service Water Use Def #{use_rate.round(2)}gal/min")

      sensible_fraction = 0.2
      latent_fraction = 0.05

      # Target mixed water temperature
      mixed_water_temp_f = prototype_input["#{type}_water_use_temperature"]
      mixed_water_temp_sch = OpenStudio::Model::ScheduleRuleset.new(self)
      mixed_water_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),OpenStudio.convert(mixed_water_temp_f,'F','C').get)
      water_fixture_def.setTargetTemperatureSchedule(mixed_water_temp_sch)

      sensible_fraction_sch = OpenStudio::Model::ScheduleRuleset.new(self)
      sensible_fraction_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),sensible_fraction)
      water_fixture_def.setSensibleFractionSchedule(sensible_fraction_sch)

      latent_fraction_sch = OpenStudio::Model::ScheduleRuleset.new(self)
      latent_fraction_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),latent_fraction)
      water_fixture_def.setSensibleFractionSchedule(latent_fraction_sch)

      # Water use equipment
      water_fixture = OpenStudio::Model::WaterUseEquipment.new(water_fixture_def)
      schedule = self.add_schedule(water_end_use[2])
      water_fixture.setFlowRateFractionSchedule(schedule)
      water_fixture.setName("#{space_name} Service Water Use #{use_rate.round(2)}gal/min")
      swh_connection.addWaterUseEquipment(water_fixture)

      # Connect the water use connection to the SWH loop
      swh_loop.addDemandBranchForComponent(swh_connection)
    end
  end

  def add_refrigeration(building_type, building_vintage, climate_zone, prototype_input, standards)
    # TODO: Check different vintage to see what parameters are required.
    # refrigeration_standards = standards['refrigeration']
    # climate_zone_sets = self.find_all_climate_zone_sets(climate_zone)
    # refrigeration_objs = []
    # climate_zone_sets.each do |climate_zone_set|
    #   # Find the initial Chiller properties based on initial inputs
    #   search_criteria = {
    #       'template' => building_vintage,
    #       'climate_zone_set' => climate_zone_set,
    #       'building_type' => building_type
    #   }
    #   refrigeration_objs = self.find_objects(refrigeration_standards, search_criteria)
    #   break if refrigeration_objs.size > 0
    # end
    #
    # refrigeration_objs.each do |obj|
    #   self.add_refrigeration_case(obj)
    # end

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Started Adding Refrigeration System")

    #Schedule Ruleset
    defrost_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    defrost_sch.setName("Refrigeration Defrost Schedule")
    #All other days
    defrost_sch.defaultDaySchedule.setName("Refrigeration Defrost Schedule Default")
    defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,11,0,0), 0)
    defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,11,20,0), 1)
    defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,23,0,0), 0)
    defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,23,20,0), 1)
    defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0)

    #Schedule Ruleset
    defrost_dripdown_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    defrost_dripdown_sch.setName("Refrigeration Defrost DripDown Schedule")
    #All other days
    defrost_dripdown_sch.defaultDaySchedule.setName("Refrigeration Defrost DripDown Schedule Default")
    defrost_dripdown_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,11,0,0), 0)
    defrost_dripdown_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,11,30,0), 1)
    defrost_dripdown_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,23,0,0), 0)
    defrost_dripdown_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,23,30,0), 1)
    defrost_dripdown_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0)

    #Schedule Ruleset
    case_credit_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    case_credit_sch.setName("Refrigeration Case Credit Schedule")
    #All other days
    case_credit_sch.defaultDaySchedule.setName("Refrigeration Case Credit Schedule Default")
    case_credit_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,7,0,0), 0.2)
    case_credit_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,21,0,0), 0.4)
    case_credit_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0.2)

    space = self.getSpaceByName('Kitchen_Flr_6')
    if space.empty?
      OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "No space called Kitchen was found in the model")
      return false
    end
    space = space.get
    thermal_zone = space.thermalZone
    if thermal_zone.empty?
      OpenStudio::logFree(OpenStudio::Error, 'openstudio.model.Model', "No thermal zone was created for the space called #{space_name}")
      return false
    end
    thermal_zone = thermal_zone.get

    ref_sys1 = OpenStudio::Model::RefrigerationSystem.new(self)
    ref_sys1.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(self))
    condenser1 = OpenStudio::Model::RefrigerationCondenserAirCooled.new(self)
    condenser1.setRatedFanPower(350)

    ref_case1 = OpenStudio::Model::RefrigerationCase.new(self, defrost_sch)
    ref_case1.setAvailabilitySchedule(self.alwaysOnDiscreteSchedule)
    ref_case1.setThermalZone(thermal_zone)
    ref_case1.setRatedTotalCoolingCapacityperUnitLength(367.0)
    ref_case1.setCaseLength(7.32)
    ref_case1.setCaseOperatingTemperature(-23.0)
    ref_case1.setStandardCaseFanPowerperUnitLength(34)
    ref_case1.setOperatingCaseFanPowerperUnitLength(34)
    ref_case1.setStandardCaseLightingPowerperUnitLength(16.4)
    ref_case1.resetInstalledCaseLightingPowerperUnitLength

    ref_case1.setCaseLightingSchedule(self.add_schedule('HotelLarge BLDG_LIGHT_SCH'))
    ref_case1.setHumidityatZeroAntiSweatHeaterEnergy(0)
    ref_case1.setCaseDefrostPowerperUnitLength(273.0)
    ref_case1.setCaseDefrostType('Electric')
    ref_case1.resetDesignEvaporatorTemperatureorBrineInletTemperature

    ref_case1.setRatedAmbientTemperature(23.88)
    ref_case1.setRatedLatentHeatRatio(0.1)
    ref_case1.setRatedRuntimeFraction(0.4)
    ref_case1.setLatentCaseCreditCurve(self.add_curve('HotelLarge Kitchen_Flr_6_Case:1_WALKINFREEZERSingleShelfHorizontal_LatentEnergyMult',standards))
    ref_case1.setCaseLightingSchedule(self.add_schedule('HotelLarge BLDG_LIGHT_SCH'))
    ref_case1.setFractionofAntiSweatHeaterEnergytoCase(0)

    ref_case1.setCaseHeight(0)
    ref_case1.setCaseDefrostDripDownSchedule(defrost_dripdown_sch)
    ref_case1.setUnderCaseHVACReturnAirFraction(0)
    # TODO: setRefrigeratedCaseRestockingSchedule is not working
    ref_case1.setRefrigeratedCaseRestockingSchedule(self.add_schedule('HotelLarge Kitchen_Flr_6_Case:1_WALKINFREEZER_WalkInStockingSched'))
    ref_case1.setCaseCreditFractionSchedule(case_credit_sch)

    ref_sys1.addCase(ref_case1)
    ref_sys1.setRefrigerationCondenser(condenser1)
    ref_sys1.setSuctionPipingZone(thermal_zone)

    #Schedule Ruleset
    defrost_sch2 = OpenStudio::Model::ScheduleRuleset.new(self)
    defrost_sch2.setName('Refrigeration Defrost Schedule 2')
    #All other days
    defrost_sch2.defaultDaySchedule.setName('Refrigeration Defrost Schedule Default 2')
    defrost_sch2.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0)

    ref_sys2 = OpenStudio::Model::RefrigerationSystem.new(self)
    ref_sys2.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(self))
    condenser2 = OpenStudio::Model::RefrigerationCondenserAirCooled.new(self)
    condenser2.setRatedFanPower(350)

    ref_case2 = OpenStudio::Model::RefrigerationCase.new(self, defrost_sch2)
    ref_case2.setThermalZone(thermal_zone)
    ref_case2.setAvailabilitySchedule(self.alwaysOnDiscreteSchedule)
    ref_case2.setRatedTotalCoolingCapacityperUnitLength(734.0)
    ref_case2.setCaseLength(3.66)
    ref_case2.setCaseOperatingTemperature(2.0)
    ref_case2.setStandardCaseFanPowerperUnitLength(55)
    ref_case2.setOperatingCaseFanPowerperUnitLength(55)
    ref_case2.setStandardCaseLightingPowerperUnitLength(33)
    ref_case2.resetInstalledCaseLightingPowerperUnitLength

    ref_case2.setCaseLightingSchedule(self.add_schedule('HotelLarge BLDG_LIGHT_SCH'))
    ref_case2.setHumidityatZeroAntiSweatHeaterEnergy(0)
    ref_case2.setCaseDefrostType('None')
    ref_case2.resetDesignEvaporatorTemperatureorBrineInletTemperature

    ref_case2.setRatedAmbientTemperature(23.88)
    ref_case2.setRatedLatentHeatRatio(0.08)
    ref_case2.setRatedRuntimeFraction(0.85)
    ref_case2.setLatentCaseCreditCurve(self.add_curve('HotelLarge Kitchen_Flr_6_Case:2_SELFCONTAINEDDISPLAYCASEMultiShelfVertical_LatentEnergyMult',standards))
    ref_case2.setFractionofAntiSweatHeaterEnergytoCase(0.2)

    ref_case2.setCaseHeight(0)
    ref_case2.setCaseDefrostPowerperUnitLength(0)
    ref_case2.setUnderCaseHVACReturnAirFraction(0.05)
    ref_case2.setRefrigeratedCaseRestockingSchedule(self.add_schedule('HotelLarge Kitchen_Flr_6_Case:2_SELFCONTAINEDDISPLAYCASE_CaseStockingSched'))

    ref_sys2.addCase(ref_case2)
    ref_sys2.setRefrigerationCondenser(condenser2)
    ref_sys2.setSuctionPipingZone(thermal_zone)

    OpenStudio::logFree(OpenStudio::Info, "openstudio.model.Model", "Finished adding Refrigeration System")

    return true
  end #add refrigeration
end
