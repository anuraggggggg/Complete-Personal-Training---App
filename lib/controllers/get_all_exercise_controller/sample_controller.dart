// import 'dart:convert';

// import 'package:get/get_rx/src/rx_types/rx_types.dart';
// import 'package:get/get_state_manager/src/simple/get_controllers.dart';
// import 'package:http/http.dart' as http;
// import 'package:mighty_fitness/Chat/model/subscription_diet_plan_model.dart';
// import 'package:mighty_fitness/models/diet_models.dart' hide Data;
// import 'package:shared_preferences/shared_preferences.dart';

// class  FetchDietList  extends GetxController{

//   final RxBool isLaoding =  false.obs;
//   final RxBool isError = false.obs;
//   final RxString errorMessage = "".obs;
//   final RxString subscriptionMessage = "".obs;

//   final String  baseUrl = " ";

//   final RxList<Data> fetchList= <Data>[].obs;


//   Future<void> fetchListController(String variety, int  categoryId,int  language, String gender ) async {
//     isLaoding.value=true;
//     isError.value= false;

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("TOKEN");
//       final userId = prefs.getInt("USER_ID"); 

//       if(token == null || userId ==null){
//         isError.value= true;
//         errorMessage.value= "User Not Logged In";
//       }

//       final uri =  Uri.parse(baseUrl).replace(
//         queryParameters: {
//           "variety": variety.toString,
//           "category": categoryId.toString(),
//           "language_id": language.toString(),
//           "gender": gender
//         }
//       );


//       final  response = await http.get(uri,headers:{
//         "Accept": "application/json",
//         "Authorization": "Bearer $token",
//       });

//       print('status code = ${response.statusCode}');
//       print('status code = ${response.body}');

//       if(response.statusCode ==200){
//         final jsonData= jsonDecode(response.body);
//         final model = DieatListModel.fromJson(jsonData);

//         if(model.data !=null && model.data!.isNotEmpty){
//            fetchList.assignAll(model.data!);
//            print("Diets Loaded= ${fetchList.length}");
//         }else{
//           print("Empty list-> subscription required");
//         }
        
//       }
//     }catch (e){
      
//     }
//   }





// }