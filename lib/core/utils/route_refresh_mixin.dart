import 'package:flutter/widgets.dart';
import 'package:front/core/router/route_observer.dart';

mixin RouteRefreshMixin<T extends StatefulWidget> on State<T> implements RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    onRouteResumed();
  }

  @override
  void didPush() {}

  @override
  void didPushNext() {}

  @override
  void didPop() {}

  void onRouteResumed();
}
