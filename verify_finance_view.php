<?php
require '/home/new/web/graphy7.tech/public_html/vendor/autoload.php';
$app = require '/home/new/web/graphy7.tech/public_html/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();
view()->share('errors', new Illuminate\Support\ViewErrorBag());
$request = Illuminate\Http\Request::create('/admin/finance', 'GET');
$view = app(App\Http\Controllers\Admin\FinanceController::class)->index($request, app(App\Http\Controllers\Api\AdminController::class));
$html = $view->render();
echo strpos($html, 'admin/finance/export') !== false ? 'finance-view-ok' : 'finance-view-rendered';
echo PHP_EOL;