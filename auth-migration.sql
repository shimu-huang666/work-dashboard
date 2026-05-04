-- ============================================
-- 添加登录功能 - 数据库迁移脚本
-- ============================================
-- 使用方法：
-- 在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 1. 添加 user_id 字段到所有表
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE daily_logs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE plans ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE notes ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

-- 2. 为 user_id 创建索引
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_logs_user_id ON daily_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_plans_user_id ON plans(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);

-- 3. 删除旧的 RLS 策略（删除所有可能存在的策略）
-- tasks 表策略
DROP POLICY IF EXISTS "Allow all operations on tasks" ON tasks;
DROP POLICY IF EXISTS "Allow all" ON tasks;
DROP POLICY IF EXISTS "Users can only access own tasks" ON tasks;

-- daily_logs 表策略
DROP POLICY IF EXISTS "Allow all operations on daily_logs" ON daily_logs;
DROP POLICY IF EXISTS "Allow all" ON daily_logs;
DROP POLICY IF EXISTS "Users can only access own daily_logs" ON daily_logs;

-- plans 表策略
DROP POLICY IF EXISTS "Allow all operations on plans" ON plans;
DROP POLICY IF EXISTS "Allow all" ON plans;
DROP POLICY IF EXISTS "Users can only access own plans" ON plans;

-- notes 表策略
DROP POLICY IF EXISTS "Allow all operations on notes" ON notes;
DROP POLICY IF EXISTS "Allow all" ON notes;
DROP POLICY IF EXISTS "Users can only access own notes" ON notes;

-- 4. 创建用户级 RLS 策略
-- tasks 表策略
CREATE POLICY "Users can only access own tasks" ON tasks
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- daily_logs 表策略
CREATE POLICY "Users can only access own daily_logs" ON daily_logs
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- plans 表策略
CREATE POLICY "Users can only access own plans" ON plans
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- notes 表策略
CREATE POLICY "Users can only access own notes" ON notes
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 完成提示
DO $$
BEGIN
  RAISE NOTICE '登录功能迁移完成！已为所有表添加 user_id 字段和用户级 RLS 策略';
END $$;
