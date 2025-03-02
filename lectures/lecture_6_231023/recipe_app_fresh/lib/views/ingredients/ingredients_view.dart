import 'package:flutter/material.dart';
import 'package:recipe_app/views/ingredients/create_ingredient_modal.dart';
import 'package:recipe_model/recipe_model.dart';
import 'package:uuid/uuid.dart';

class FadePageRoute extends MaterialPageRoute {
  FadePageRoute({required super.builder});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 1500);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return ScaleTransition(
      scale: animation,
      child: SlideTransition(
        position: animation.drive(
            Tween(begin: Offset(0, 1), end: Offset(0, 0)).chain(CurveTween(
          curve: Curves.ease,
        ))),
        child: RotationTransition(
            turns: animation,
            child: FadeTransition(opacity: animation, child: child)),
      ),
    );
  }
}

class IngredientsView extends StatefulWidget {
  const IngredientsView({Key? key}) : super(key: key);

  @override
  State<IngredientsView> createState() => _IngredientsViewState();
}

class _IngredientsViewState extends State<IngredientsView> {
  // stateful widget as we will want to update the ingredients list when actions are performed

  var ingredientsFuture = IngredientRepository.instance.list_two();

  @override
  Widget build(BuildContext context) {
    // create a scaffold with a futurebuilding
    // show progress when loading
    // otherwise show ingredients as listtiles
    // add a fab which creates ingredients and updates the list
    // fab can use a modal bottom sheet to show create ingredient modal

    return FutureBuilder(
        future: ingredientsFuture,
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            final ingredients = snapshot.data!.value!;

            return Scaffold(
              body: ListView.builder(
                  itemBuilder: (context, index) {
                    final ingredient = ingredients[index];
                    return ListTile(
                      key: ValueKey(ingredient.id),
                      onTap: () {
                        // todo: navigate to ingredient detail view
                        Navigator.of(context).push(FadePageRoute(
                            builder: (context) => IngredientDetailedView(
                                  ingredient: ingredient,
                                )));
                      },
                      title: Text(ingredient.name),
                      subtitle: Text(ingredient.description),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          // todo: open popup dialog, delete on confirm
                          showDialog<void>(
                            context: context,
                            barrierDismissible: false, // user must tap button!
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Deletion dialog'),
                                content: Text("confirm ingredient delete"),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('delete'),
                                    onPressed: () async {
                                      await IngredientRepository.instance
                                          .delete(ingredient.id);
                                      ingredientsFuture = IngredientRepository
                                          .instance
                                          .list()
                                          .whenComplete(() {
                                        setState(() {});
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                  itemCount: ingredients.length),
              floatingActionButton: FloatingActionButton.extended(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.5,
                          color: Colors.amber,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text('Add new ingredient'),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      child: const Text('cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    ElevatedButton(
                                      child: const Text('Add new'),
                                      onPressed: () {
                                        IngredientRepository.instance.create(
                                            Ingredient(
                                                id: const Uuid().v4(),
                                                name: "test",
                                                description: "test"));
                                        setState(() {
                                          ingredientsFuture =
                                              IngredientRepository.instance
                                                  .list();
                                        });
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                backgroundColor: Colors.green,
                                                content: Text(
                                                    "Successfully added ingredient")));
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  label: Text("Add Ingredient")),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("error"));
          } else {
            // allt under 50ms är ungefär omedelbart
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}

class IngredientDetailedView extends StatelessWidget {
  const IngredientDetailedView({Key? key, required this.ingredient})
      : super(key: key);

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ingredient.name),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        color: Colors.greenAccent,
        child: Center(
          child: Text(ingredient.description),
        ),
      ),
    );
  }
}
