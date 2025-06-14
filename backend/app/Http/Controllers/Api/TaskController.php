<?php

namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Task;
class TaskController extends Controller
{
public function index(Request $request) {
$tasks = Task::where('user_id', $request->user()->id)->get();
return response()->json($tasks);
}
public function store(Request $request) {
$request->validate([
'title' => 'required|string',
'priority' => 'required|in:low,medium,high',
'due_date' => 'required|date',
]);
$task = Task::create([
'title' => $request->title,
'priority' => $request->priority,
'due_date' => $request->due_date,
'is_done' => $request->is_done,
'user_id' => $request->user()->id,
]);
return response()->json($task, 201);
}
public function update(Request $request, $id) {
    $task = Task::where('id', $id)
                ->where('user_id', $request->user()->id)
                ->firstOrFail();
    $task->update($request->only(['title', 'priority', 'due_date', 'is_done']));
    return response()->json($task);
}
public function destroy(Request $request, $id)
{
    $task = Task::where('id', $id)
                ->where('user_id', $request->user()->id)
                ->first();
    if (!$task) {
        return response()->json(['message' => 'Task not found'], 404);
    }
    $task->delete();
    return response()->json(['message' => 'Task deleted successfully'], 200);
}

}
