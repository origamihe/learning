<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const menuOpen = ref(false)

function toggleMenu() {
  menuOpen.value = !menuOpen.value
}

function closeMenu() {
  menuOpen.value = false
}

function handleLogout() {
  authStore.logout()
  router.push('/login')
}

const navItems = [
  { path: '/home', label: '首页' },
  { path: '/courses', label: '课程' },
  { path: '/wrong-book', label: '错题本' },
  { path: '/profile', label: '个人中心' },
]

const adminItems = [
  { path: '/admin/dashboard', label: '管理后台' },
  { path: '/admin/users', label: '用户管理' },
  { path: '/admin/courses', label: '课程管理' },
  { path: '/admin/sections', label: '章节管理' },
  { path: '/admin/questions', label: '题目管理' },
  { path: '/admin/exams', label: '考试管理' },
]
</script>

<template>
  <nav class="topnav">
    <div class="topnav-inner">
      <!-- Logo -->
      <router-link to="/home" class="logo" @click="closeMenu">
        <svg class="logo-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M12 2L2 7l10 5 10-5-10-5z" />
          <path d="M2 17l10 5 10-5" />
          <path d="M2 12l10 5 10-5" />
        </svg>
        <span class="logo-text">Learning</span>
      </router-link>

      <!-- 桌面端导航 -->
      <div class="nav-links">
        <router-link
          v-for="item in navItems"
          :key="item.path"
          :to="item.path"
          class="nav-link"
          :class="{ active: route.path === item.path }"
        >
          {{ item.label }}
        </router-link>

        <!-- 管理员菜单 -->
        <template v-if="authStore.isAdmin">
          <span class="nav-divider"></span>
          <router-link
            v-for="item in adminItems"
            :key="item.path"
            :to="item.path"
            class="nav-link admin-link"
            :class="{ active: route.path === item.path }"
          >
            {{ item.label }}
          </router-link>
        </template>
      </div>

      <!-- 用户操作 -->
      <div class="nav-actions">
        <span class="user-greeting">{{ authStore.user?.nickname || authStore.user?.username }}</span>
        <button class="logout-btn" @click="handleLogout">退出</button>
      </div>

      <!-- 移动端 Hamburger -->
      <button class="hamburger" :class="{ open: menuOpen }" @click="toggleMenu">
        <span></span>
        <span></span>
        <span></span>
      </button>
    </div>

    <!-- 移动端菜单 -->
    <transition name="slide">
      <div v-if="menuOpen" class="mobile-menu" @click="closeMenu">
        <router-link
          v-for="item in navItems"
          :key="item.path"
          :to="item.path"
          class="mobile-link"
          :class="{ active: route.path === item.path }"
        >
          {{ item.label }}
        </router-link>
        <template v-if="authStore.isAdmin">
          <div class="mobile-divider"></div>
          <router-link
            v-for="item in adminItems"
            :key="item.path"
            :to="item.path"
            class="mobile-link admin-link"
            :class="{ active: route.path === item.path }"
          >
            {{ item.label }}
          </router-link>
        </template>
        <div class="mobile-divider"></div>
        <button class="mobile-logout" @click="handleLogout">退出登录</button>
      </div>
    </transition>
  </nav>
</template>

<style scoped>
.topnav {
  position: sticky;
  top: 0;
  z-index: 100;
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: saturate(180%) blur(20px);
  -webkit-backdrop-filter: saturate(180%) blur(20px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.topnav-inner {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 24px;
  height: 52px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

/* Logo */
.logo {
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
  color: #1d1d1f;
  font-weight: 700;
  font-size: 18px;
  flex-shrink: 0;
}

.logo-icon {
  width: 24px;
  height: 24px;
  color: #0071e3;
}

.logo-text {
  letter-spacing: -0.3px;
}

/* 桌面导航 */
.nav-links {
  display: flex;
  align-items: center;
  gap: 4px;
}

.nav-link {
  padding: 6px 14px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  color: #424245;
  text-decoration: none;
  transition: all 0.2s;
}

.nav-link:hover {
  background: rgba(0, 0, 0, 0.04);
  color: #1d1d1f;
}

.nav-link.active {
  background: rgba(0, 113, 227, 0.08);
  color: #0071e3;
}

.nav-divider {
  width: 1px;
  height: 20px;
  background: #d2d2d7;
  margin: 0 6px;
}

.admin-link {
  color: #86868b;
  font-size: 13px;
}

/* 用户操作 */
.nav-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

.user-greeting {
  font-size: 14px;
  color: #86868b;
}

.logout-btn {
  padding: 6px 16px;
  border: 1px solid #d2d2d7;
  border-radius: 9999px;
  background: transparent;
  color: #86868b;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.logout-btn:hover {
  border-color: #ff3b30;
  color: #ff3b30;
  background: rgba(255, 59, 48, 0.04);
}

/* Hamburger */
.hamburger {
  display: none;
  flex-direction: column;
  gap: 5px;
  padding: 4px;
  border: none;
  background: transparent;
  cursor: pointer;
}

.hamburger span {
  display: block;
  width: 20px;
  height: 2px;
  background: #1d1d1f;
  border-radius: 2px;
  transition: all 0.3s;
}

.hamburger.open span:nth-child(1) {
  transform: translateY(7px) rotate(45deg);
}

.hamburger.open span:nth-child(2) {
  opacity: 0;
}

.hamburger.open span:nth-child(3) {
  transform: translateY(-7px) rotate(-45deg);
}

/* 移动端菜单 */
.mobile-menu {
  display: none;
  background: rgba(255, 255, 255, 0.98);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
  padding: 8px 24px 16px;
}

.mobile-link {
  display: block;
  padding: 12px 0;
  font-size: 16px;
  font-weight: 500;
  color: #1d1d1f;
  text-decoration: none;
  border-bottom: 1px solid #f5f5f7;
}

.mobile-link.active {
  color: #0071e3;
}

.mobile-divider {
  height: 1px;
  background: #f1f1f3;
  margin: 8px 0;
}

.mobile-logout {
  width: 100%;
  padding: 12px 0;
  border: none;
  background: transparent;
  color: #ff3b30;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  text-align: left;
}

/* Slide 动画 */
.slide-enter-active,
.slide-leave-active {
  transition: all 0.3s ease;
}

.slide-enter-from,
.slide-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

/* 响应式 */
@media (max-width: 768px) {
  .nav-links,
  .nav-actions {
    display: none;
  }

  .hamburger {
    display: flex;
  }

  .mobile-menu {
    display: block;
  }
}
</style>
